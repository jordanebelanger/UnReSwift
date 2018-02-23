//
//  Action.swift
//  UnRedux
//
//  Created by jordanebelanger on 1/16/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

public protocol AnyAction {
    /// Type erasure of the Action reduce function.
    /// Do not implement in your `Action`s.
    func _reduce(_ state: Any) -> Any
}

public protocol Action: AnyAction {
    associatedtype ActionStateType: StateType
    
    func reduce(_ state: ActionStateType) -> ActionStateType
}

extension Action {
    public func _reduce(_ state: Any) -> Any {
        return reduce(state as! ActionStateType)
    }
}
