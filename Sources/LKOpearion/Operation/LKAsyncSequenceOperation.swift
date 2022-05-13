//
//  LKSequenceAsyncOperation.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/13.
//

import Foundation

open class LKAsyncSequenceOperation: LKAsyncOperation {
    
    private var block: (LKBlockController) -> Void = { _ in }
    
    private var failureBlock: (Error) -> Void = { _ in }
    
    private var successBlock: () -> Void = { }
    
    public init(_ block: @escaping (LKBlockController) -> Void = { _ in }) {
        self.block = block
    }
    
    public override func main() {
        
        let controller = LKBlockController(
            success: successBlock,
            failure: failureBlock,
            complete: completeBlock,
            isCancelled: { [weak self] in
                guard let self = self else { return true }
                return self.isCancelled
            }
        )
        
        block(controller)
    }
    
    public func failure(_ failureBlock: @escaping (Error) -> Void) -> Self {
        self.failureBlock = failureBlock
        return self
    }
    
    public func success(_ successBlock: @escaping () -> Void) -> Self {
        self.successBlock = successBlock
        return self
    }
    
    public func block(_ block: @escaping (LKBlockController) -> Void) -> Self {
        self.block = block
        return self
    }
}
