//
//  Weak.swift
//  UnRedux
//
//  Created by jordanebelanger on 1/24/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

struct Weak<T> {
    private weak var _object: AnyObject?
    public var object: T? {
        get { return _object as? T }
        set { _object = newValue as AnyObject }
    }
    
    init?(object: T) {
        self._object = object as AnyObject
    }
}

extension Weak where T: AnyObject {
    init(object: T) {
        self._object = object
    }
}
