//
//  ThreadSafeAccesser.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/21.
//

import Foundation

class ThreadSafeAccesser<T> {
    
    private let queue = DispatchQueue(label: "ThreadSafeAccesser\(Int.random(in: 0...10000))", attributes: .concurrent)

    var _value: T
    
    init(_ value: T) {
        self._value = value
    }
    
    func fetchFromValue() -> T {
        queue.sync {
            _value
        }
    }
    
    func writeIntoValue(_ value: T) {
        queue.sync(flags: .barrier) {
            _value = value
        }
    }
}
