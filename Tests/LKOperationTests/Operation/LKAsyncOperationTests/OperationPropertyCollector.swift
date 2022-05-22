//
//  File.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/14.
//

import Foundation
@testable import LKOperation

struct OperationPropertyCollector {
    let isReady: Bool
    let isExecuted: Bool
    let isFinished: Bool
    let isAsynchronous: Bool
    let isPending: Bool
    
    static func object(with op: LKAsyncOperation) -> Self {
        OperationPropertyCollector(
            isReady: op.isReady,
            isExecuted: op.isExecuting,
            isFinished: op.isFinished,
            isAsynchronous: op.isAsynchronous,
            isPending: op.isPending
        )
    }
}

extension OperationPropertyCollector: Equatable {
    
}
