//
//  TaskRunner.swift
//  UnRedux
//
//  Created by jordanebelanger on 1/31/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

public class TaskRunner<TaskRunnerStateType: StateType> {
    
    public typealias TaskCallback = (_ state: TaskRunnerStateType, _ isCancelled: Bool) -> Void
    
    /// The tasks currently running (or about to be ran). The type of a task is used as
    /// the key here, i.e `type(of: A_TASK)`
    private var tasks: [String: [TaskContainer<TaskRunnerStateType>]] = [:]
    
    private let store: Store<TaskRunnerStateType>
    
    // A lock is used to control access to `tasks` incase the client is executing tasks
    // from multiple threads.
    private let lock = Lock()
    
    /// A custom dispatchQueue on which to run the tasks (async) by default.
    /// If nil, the tasks are ran on the calling queue.
    /// Default: nil
    public var dispatchQueue: DispatchQueue?
    
    /// Initiates the Task
    public init(store: Store<TaskRunnerStateType>) {
        self.store = store
    }
    
    public func takeFirst<T: Task>(_ task: T, dispatchQueue: DispatchQueue? = nil, callback: TaskCallback? = nil) where T.TaskActionStateType == TaskRunnerStateType {
        let taskDispatchQueue = dispatchQueue ?? self.dispatchQueue
        taskDispatchQueue.asyncOrContinue { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.lock.lock()
            strongSelf.cleanUpFinishedTasks(withName: task.name)
            if let currentTask = strongSelf.tasks[task.name]?.first, currentTask.finished == false {
                // Ignoring the new task passed in if there is already a current `Task` of that type going on.
                // You still get a `TaskCancellationToken` to cancel the ongoing task.
                strongSelf.lock.unlock()
                return
            }
            
            let taskContainer = strongSelf.taskContainer(forTask: task, callback: callback)
            strongSelf.tasks[task.name] = [taskContainer]
            
            strongSelf.lock.unlock()
            taskContainer.workItem.perform()
        }
    }
    
    public func takeEvery<T: Task>(_ task: T, dispatchQueue: DispatchQueue? = nil, callback: TaskCallback? = nil) where T.TaskActionStateType == TaskRunnerStateType {
        let taskDispatchQueue = dispatchQueue ?? self.dispatchQueue
        taskDispatchQueue.asyncOrContinue { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.lock.lock()
            strongSelf.cleanUpFinishedTasks(withName: task.name)
            
            let taskContainer = strongSelf.taskContainer(forTask: task, callback: callback)
            
            if strongSelf.tasks[task.name] != nil {
                strongSelf.tasks[task.name]!.append(taskContainer)
            } else {
                strongSelf.tasks[task.name] = [taskContainer]
            }
            strongSelf.lock.unlock()
            taskContainer.workItem.perform()
        }
    }
    
    public func takeLatest<T: Task>(_ task: T, dispatchQueue: DispatchQueue? = nil, callback: TaskCallback? = nil) where T.TaskActionStateType == TaskRunnerStateType {
        let taskDispatchQueue = dispatchQueue ?? self.dispatchQueue
        taskDispatchQueue.asyncOrContinue { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.lock.lock()
            strongSelf.cleanUpFinishedTasks(withName: task.name)
            
            if let currentTask = strongSelf.tasks[task.name]?.first, currentTask.finished == false {
                // Cancelling the ongoing task
                currentTask.cancel()
            }
            
            let taskContainer = strongSelf.taskContainer(forTask: task, callback: callback)
            strongSelf.tasks[task.name] = [taskContainer]
            
            strongSelf.lock.unlock()
            taskContainer.workItem.perform()
        }
    }
    
    
    private func taskContainer<T: Task>(forTask task: T, callback: TaskCallback? = nil) -> TaskContainer<TaskRunnerStateType> where T.TaskActionStateType == TaskRunnerStateType {
        let taskContainer = TaskContainer(task: task.asAnyTask)
        
        taskContainer.workItem = DispatchWorkItem { [weak self, weak taskContainer] in
            guard let strongSelf = self, let strongTaskContainer = taskContainer, strongTaskContainer.finished == false else {
                return
            }
            
            let finishCallback: () -> Void = {
                taskContainer?.finish()
                callback?(strongSelf.store.state, false)
            }
            
            let dispatchFunction: ((TaskRunnerStateType) -> AnyAction) -> Void = { dispatch in
                guard let strongSelf = self, let strongTaskContainer = taskContainer, strongTaskContainer.finished == false else {
                    return
                }
                
                let action = dispatch(strongSelf.store.state)
                safeDispatchMainSync {
                    guard let strongSelf = self else { return }
                    strongSelf.store._dispatch(action)
                }
            }
            
            strongTaskContainer.task.exec(state: strongSelf.store.state,
                                          dispatch: dispatchFunction,
                                          finish: finishCallback)
        }
        
        return taskContainer
    }
    
    private func cleanUpFinishedTasks(withName name: String) {
        guard let tasks = tasks[name] else {
            return
        }
        
        self.tasks[name] = tasks.filter { $0.finished == false }
    }
    
}

public struct TaskCancellationToken {
    fileprivate let taskContainer: Cancellable
    
    //    private(set) var isCancelled: Bool = false
    
    /// Register a closure that will be called if the task associated with this token gets cancelled.
    public func register(closure: @escaping () -> Void) {
        taskContainer.registerCancellationObserver(closure: closure)
    }
    
    /// Will only ever cancel your Task once, meaning the cancellation notification
    /// closures you register with this `CancellationToken` will only ever be called once
    /// even if you call `cancel` multiple times.
    public func cancel() {
        taskContainer.cancel()
    }
    
}

private protocol Cancellable {
    func cancel()
    func registerCancellationObserver(closure: @escaping () -> Void)
}

private class TaskContainer<TaskActionStateType: StateType>: Cancellable {
    var workItem: DispatchWorkItem!
    let task: AnyTask<TaskActionStateType>
    
    private(set) var finished: Bool = false
    
    private var cancellationObservers = [() -> Void]()
    
    private let lock = Lock()
    
    init(task: AnyTask<TaskActionStateType>) {
        self.task = task
    }
    
    func finish() {
        if finished { return } // Fast precheck to avoid locking unecessarily
        lock.sync {
            if !finished {
                finished = true
            }
        }
    }
    
    func cancel() {
        if finished { return } // Fast precheck to avoid locking unecessarily
        lock.sync {
            if !finished {
                finished = true
                cancellationObservers.forEach { $0() }
                cancellationObservers.removeAll()
            }
        }
    }
    
    func registerCancellationObserver(closure: @escaping () -> Void) {
        if finished { closure(); return } // fast pre-lock check
        lock.sync {
            if finished {
                closure()
            } else {
                cancellationObservers.append(closure)
            }
        }
    }
    
}
