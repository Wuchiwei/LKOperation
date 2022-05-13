//
//  AsyncBlockOperation.swift
//
//  Created by WU CHIH WEI on 2022/5/11.
//

import Foundation

/// AsyncOperation with will define callback to achieve async operation with state management.
///
/// You can add mutiple type of call back to be invoked in the Operation
///  - block closure for saving the async task
///  - failureBlock closure should be invoked when async task rising an error
///  - successBlock closure should be invoked when aync task complete it's job successfully
///  - deferBlock should be called inside the defer block of async task
///

public class LKAsyncBlockOperation: LKAsyncOperation {
    
    private var block: (LKAsyncBlockOperation) -> Void = { _ in }
    
    public init(_ block: @escaping (LKAsyncBlockOperation) -> Void = { _ in }) {
        self.block = block
    }
    
    public override func main() {
        block(self)
    }
    
    public func block(_ block: @escaping (LKAsyncBlockOperation) -> Void) -> Self {
        self.block = block
        return self
    }
}
