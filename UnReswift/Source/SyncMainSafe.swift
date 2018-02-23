//
//  SyncMainSafe.swift
//  UnReswift
//
//  Created by jordanebelanger on 1/31/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

func safeDispatchMainSync(_ block: () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}
