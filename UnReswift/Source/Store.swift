//
//  Store.swift
//  UnRedux
//
//  Created by jordanebelanger on 1/17/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

public class Store<State: StateType> {
    
    public typealias ActionCreator = (_ state: State, _ store: Store) -> Action?
    
    public private(set) var state: State {
        didSet {
            subscribers = subscribers.filter { $0.object != nil }
            for sub in subscribers {
                sub.object?._newState(state: state)
            }
        }
    }
    
    private var subscribers: [Weak<AnyStoreSubscriber>] = []
    
    private var isDispatching = false
    
    public init(state: State) {
        self.state = state
    }
    
    public func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.StoreSubscriberStateType == State {
        if let index = subscribers.index(where: { $0.object === subscriber }) {
            subscribers.remove(at: index)
        }
        subscribers.append(Weak(object: subscriber)!)
        subscriber.newState(state: state)
    }
    
    public func unsubscribe<S: StoreSubscriber>(_ subscriber: S) where S.StoreSubscriberStateType == State {
        if let index = subscribers.index(where: { $0.object === subscriber }) {
            subscribers.remove(at: index)
        }
    }
    
    public func dispatch<T: Action>(_ action: T) where T.ActionStateType == State {
        guard !isDispatching else {
            fatalError("Action dispatched while a concurrent action has not yet finished dispatching. Make sure you are dispatching from the main thread only")
        }
        
        isDispatching = true
        let newState = action.reduce(state)
        isDispatching = false
        
        state = newState
    }
    
    func _dispatch(_ action: AnyAction) {
        guard !isDispatching else {
            fatalError("Action dispatched while a concurrent action has not yet finished dispatching. Make sure you are dispatching from the main thread only")
        }
        
        isDispatching = true
        let newState = action._reduce(state) as! State
        isDispatching = false
        
        state = newState
    }
    
}


