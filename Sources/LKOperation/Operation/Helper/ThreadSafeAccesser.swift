//
//  ThreadSafeAccesser.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/21.
//

import Foundation

class ThreadSafeAccesser<T> {
    
    private lazy var queue = DispatchQueue(label: "\(type(of: self))", attributes: .concurrent)

    var _value: T
    
    init(_ value: T) {
        self._value = value
    }
    
    func value() -> T {
        queue.sync {
            _value
        }
    }
    
    func setValue(_ value: T) {
        queue.sync(flags: .barrier) {
            _value = value
        }
    }
}
