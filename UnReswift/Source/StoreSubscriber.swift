//
//  StoreSubscriber.swift
//  UnReswift
//
//  Created by jordanebelanger on 1/24/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

public protocol AnyStoreSubscriber: AnyObject {
    // swiftlint:disable:next identifier_name
    func _newState(state: Any)
}

public protocol StoreSubscriber: AnyStoreSubscriber {
    associatedtype StoreSubscriberStateType
    
    func newState(state: StoreSubscriberStateType)
}

extension StoreSubscriber {
    // swiftlint:disable:next identifier_name
    public func _newState(state: Any) {
        newState(state: state as! StoreSubscriberStateType)
    }
}
