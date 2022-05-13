//
//  AsyncOperationQueue.swift
//  StreamVideo
//
//  Created by WU CHIH WEI on 2022/5/12.
//  Copyright © 2022 HancockAPP. All rights reserved.
//

import Foundation

public class LKAsyncSequenceOperationQueue: OperationQueue {
    
    public typealias AsyncCompletionBlock = (Result<Void, Error>) -> Void
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    private let group = DispatchGroup()
    
    private var completionBlock: AsyncCompletionBlock = { _ in }
    
    private var error: Error?
    
    private func completeBlock(for operation: LKAsyncSequenceOperation) -> (() -> Void) {
        
        return { [weak self] in
            operation.setState(.finished)
            self?.group.leave()
        }
    }
    
    private func failureBlock(in operation: LKAsyncSequenceOperation) -> ((Error) -> Void)  {
        
        return { [weak self] error in
            
            defer {
                self?.semaphore.signal()
            }
            
            guard let self = self else { return }
            
            self.semaphore.wait()
            
            guard !operation.isCancelled else {
                return
            }
            
            self.error = error
            self.cancelAllOperations()
        }
    }
    
    private func addAsyncOperation(_ operation: LKAsyncSequenceOperation) {
        let completionOperation = operation
            .complete(self.completeBlock(for: operation))
            .failure(self.failureBlock(in: operation))
        
        super.addOperation(completionOperation)
    }
    
    @discardableResult
    public func addAsyncOperationsWithExecuteConcurrently(_ operations: [LKAsyncSequenceOperation]) -> Self {
        for operation in operations {
            group.enter()
            addAsyncOperation(operation)
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if let error = self.error {
                self.completionBlock(.failure(error))
            } else {
                self.completionBlock(.success(()))
            }
        }
        
        return self
    }
    
    @discardableResult
    public func addAsyncOperationsWithExecuteSerially(_ operations: [LKAsyncSequenceOperation]) -> Self {
        for i in 1..<operations.count {
            let previousOperation = operations[i-1]
            let nextOperation = operations[i]
            nextOperation.addDependency(previousOperation)
        }
        
        return addAsyncOperationsWithExecuteConcurrently(operations)
    }
    
    @discardableResult
    public func completion(_ block: @escaping AsyncCompletionBlock) -> Self {
        self.completionBlock = block
        return self
    }
}