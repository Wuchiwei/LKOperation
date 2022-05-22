//
//  LKAsyncBlockOperation.swift
//
//  Created by WU CHIH WEI on 2022/5/11.
//

import Foundation

/// LKAsyncBlockOperation with will define callback to achieve async operation with state management.
///
/// - warning: Inside the block, you should set operation state to finished in proper timing. Otherwise the operation never turn to finished state and cause the operation queue and this operation remain alive in memory. Which is also called memory leak.

public class LKAsyncBlockOperation: LKAsyncOperation {
    
    private var block: (LKAsyncBlockOperation) -> Void = { _ in }
    
    public init(
        _ block: @escaping (LKAsyncBlockOperation) -> Void = { _ in }
    ) {
        self.block = block
        super.init(test: {})
    }
    
    public override func main() {
        super.main()
        block(self)
    }
    
    /// Save the block and execute it in main() method.
    ///
    /// 1. Operation will invoke this block in main() method if the operation is not be cancelled.
    /// 2. Inside the block, you can check the operation's isCancelled property to determine the proccess should keep going or terminate.
    /// 2. Inside the block, you should set operation state to finished in proper timing. Otherwise the operation never turn to finished state and cause the operation queue and this operation remain alive in memory. Which is also called memory leak.
    
    @discardableResult
    public func block(_ block: @escaping (LKAsyncBlockOperation) -> Void) -> Self {
    
        self.block = block
        return self
    }
}
