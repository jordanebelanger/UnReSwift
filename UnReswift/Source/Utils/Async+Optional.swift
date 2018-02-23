//
//  DispatchQueue+Optional.swift
//  UnReswift
//
//  Created by jordanebelanger on 2/22/18.
//  Copyright © 2018 Jordane Belanger. All rights reserved.
//

import Foundation

extension Optional where Wrapped == DispatchQueue {
    func asyncOrContinue(_ code: @escaping () -> Void) {
        if case .some(let queue) = self {
            queue.async {
                code()
            }
        } else {
            code()
        }
    }
}
