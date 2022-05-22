//
//  MockLKAsyncSequenceOperationQueue.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/22.
//

import Foundation
@testable import LKOperation

class MockLKAsyncSequenceOperationQueue: LKAsyncSequenceOperationQueue {
    
    var operation: Operation?
    
    override func addAsyncOperation<T>(_ operation: LKAsyncSequenceOperation<T>) {
       
        self.operation = operation
    }
}
