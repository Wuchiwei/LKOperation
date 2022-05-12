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

class LKAsyncBlockOperation: LKAsyncOperation {
    
    private var block: (BlockController) -> Void = { _ in }
    
    private var failureBlock: (Error) -> Void = { _ in }
    
    private var successBlock: () -> Void = { }
    
    init(_ block: @escaping (BlockController) -> Void) {
        self.block = block
    }
    
    override func main() {
        
        let controller = BlockController(
            success: successBlock,
            failure: failureBlock,
            complete: completeBlock,
            cancel: { [weak self] in
                guard let self = self else { return true }
                return self.isCancelled
            }
        )
        
        block(controller)
    }
    
    func block(_ block: @escaping (BlockController) -> Void) -> Self {
        self.block = block
        return self
    }
    
    func failure(_ failureBlock: @escaping (Error) -> Void) -> Self {
        self.failureBlock = failureBlock
        return self
    }
    
    func success(_ successBlock: @escaping () -> Void) -> Self {
        self.successBlock = successBlock
        return self
    }
}

struct BlockController {
    
    let success: () -> Void
    
    let failure: (Error) -> Void
    
    let complete: () -> Void
    
    let cancel: () -> Bool
}
