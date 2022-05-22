//
//  LKSequenceAsyncOperation.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/13.
//

import Foundation

///LKAsyncSequenceOperation is designed for cooperating with LKAsyncSequenceOperationQueue

open class LKAsyncSequenceOperation<T>: LKAsyncOperation {
    
    public private(set) lazy var block: (LKBlockController<T>) -> Void = { _ in }
    
    public private(set) lazy var failureBlock: (Error) -> Void = { [weak self] error in
        
        guard self?.isCancelled == false else {
            return
        }
        self?.result = .failure(error)
    }
    
    public private(set) lazy var successBlock: (T) -> Void = { [weak self] value in
        
        guard self?.isCancelled == false else {
            return
        }
        self?.result = .success(value)
    }
    
    ///1. finishedBlock closure will be called when operation is cancelled before main() method has executed.
    ///
    ///2. If you need do something when operation is cancelled, you can add it in completeBlock through complete(:_) method.
    ///
    ///3. In your implementation of async task, you should call finished block when your task was finished or quited from the process.
    public private(set) lazy var finishedBlock: (Bool) -> Void = { [weak self] _ in
        guard let self = self else { return }
        self.setState(.finished)
    }
    
    internal var result: Result<T, Error>?
    
    public init(
        _ block: @escaping (LKBlockController<T>) -> Void = { _ in },
        testBlock: @escaping () -> Void = {}
    ){
        super.init(test: testBlock)
        self.block = block
    }
    
    public override func start() {
        guard !isCancelled else {
            finishedBlock(isCancelled)
            return
        }
        
        setState(.executing)
        main()
    }
    
    public override func main() {
        super.main()
        
        guard !isCancelled else {
            finishedBlock(isCancelled)
            return
        }
        
        let controller = LKBlockController<T>(
            success: successBlock,
            failure: failureBlock,
            finished: finishedBlock,
            isCancelled: { [weak self] in
                guard let self = self else { return true }
                return self.isCancelled
            }
        )
        
        block(controller)
    }
    
    /// Add failure block to operation
    ///
    ///In your implementation of async task, you should call controller.failure(${Error}) when your task occur error. This will invoke the block you pass in with argument. This give the block creater chance to capture the error your task produced
    @discardableResult
    public func failure(_ failureBlock: @escaping (Error) -> Void) -> Self {
        self.failureBlock = { [weak self] error in
            guard self?.isCancelled == false else {
                return
            }
            self?.result = .failure(error)
            failureBlock(error)
        }
        return self
    }
    
    /// Add success block to operation
    ///
    ///In your implementation of async task, you should call controller.success(${Object}) when your task complete successfully. This will invoke the block you pass in with argument. This give the block creater chance to capture the object your task produced
    @discardableResult
    public func success(_ successBlock: @escaping (T) -> Void) -> Self {
        self.successBlock = { [weak self] result in
            guard self?.isCancelled == false else {
                return
            }
            self?.result = .success(result)
            successBlock(result)
        }
        return self
    }
    
    /// Add finish block to operation
    ///
    ///In your implementation of async task, you should call finished block when your task was finished or quited from the process.
    @discardableResult
    public func finished(_ block: @escaping (Bool) -> Void) -> Self {
        self.finishedBlock = { [weak self] isCancelled in
            guard let self = self else { return }
            self.setState(.finished)
            block(isCancelled)
        }
        return self
    }
    
    /// Add task to operation
    ///
    /// Operation will invoke the block with well defined LKBlockController in main() method.
    @discardableResult
    public func block(_ block: @escaping (LKBlockController<T>) -> Void) -> Self {
        self.block = block
        return self
    }
    
    /// Add task to LKAsyncSequenceOperationQueue
    public func addTo(queue: LKAsyncSequenceOperationQueue) {
        queue.addAsyncOperation(self)
    }
}
