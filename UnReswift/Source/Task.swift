//
//  Task.swift
//  UnRedux
//
//  Created by jordanebelanger on 1/17/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

public protocol Task {
    associatedtype TaskActionStateType: StateType
    
    typealias DispatchFunction = ((TaskActionStateType) -> AnyAction) -> Void
    typealias FinishFunction = () -> Void
    
    func exec(state: TaskActionStateType, dispatch: @escaping DispatchFunction, finish: @escaping FinishFunction)
}

struct AnyTask<TaskActionStateType: StateType>: Task {
    private let _exec: (TaskActionStateType, @escaping DispatchFunction, @escaping FinishFunction) -> Void
    
    public init<A: Task>(_ task: A) where A.TaskActionStateType == TaskActionStateType {
        self._exec = task.exec
    }
    
    public func exec(state: TaskActionStateType,
                     dispatch: @escaping ((TaskActionStateType) -> AnyAction) -> Void,
                     finish: @escaping () -> Void) {
        _exec(state, dispatch, finish)
    }
}

extension Task {
    var asAnyTask: AnyTask<TaskActionStateType> {
        return AnyTask(self)
    }
}

extension Task {
    var name: String {
        return  "\(type(of: self))"
    }
}
