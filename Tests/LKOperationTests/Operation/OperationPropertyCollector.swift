//
//  File.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/14.
//

import Foundation

struct OperationPropertyCollector {
    let isReady: Bool
    let isExecuted: Bool
    let isFinished: Bool
    let isAsynchronous: Bool
    
    static func object(with op: Operation) -> Self {
        OperationPropertyCollector(
            isReady: op.isReady,
            isExecuted: op.isExecuting,
            isFinished: op.isFinished,
            isAsynchronous: op.isAsynchronous
        )
    }
}

extension OperationPropertyCollector: Equatable {
    
}
