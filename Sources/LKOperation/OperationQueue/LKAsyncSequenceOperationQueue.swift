//
//  AsyncOperationQueue.swift
//  StreamVideo
//
//  Created by WU CHIH WEI on 2022/5/12.
//  Copyright © 2022 HancockAPP. All rights reserved.
//

import Foundation

/// LKAsyncSequenceOperationQueue collect the operation executing result.
///  - If all executed successfully, .success event will pass to the completion block with object in a dictionary, key is relative operation identifier
///  - If any operation fails, queue will cancel the remain operations and send .failure event to completion block with error the operation produced.
///
public class LKAsyncSequenceOperationQueue: OperationQueue {
    
    public typealias AsyncCompletionBlock = (Result<[AnyHashable: Any], Error>) -> Void
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    private let group = DispatchGroup()
    
    private var completionBlock: AsyncCompletionBlock = { _ in }
    
    private var error: Error?
    
    private var _successResult: [AnyHashable: Any] = [:]
    
    private let resultQueue = DispatchQueue(label: "LKAsyncSequenceOperationQueue", attributes: .concurrent)
    
    private(set) var ops: [LKAsyncOperation] = []
    
    private func finishedBlock<T>(for operation: LKAsyncSequenceOperation<T>) -> ((Bool) -> Void) {
        
        return { [weak self] _ in
            self?.group.leave()
        }
    }
    
    private func failureBlock<T>(in operation: LKAsyncSequenceOperation<T>) -> ((Error) -> Void)  {
        
        return { [weak self, weak operation] error in
            
            defer {
                self?.semaphore.signal()
            }
            
            guard let self = self,
                  let isCancelled = operation?.isCancelled
            else {
                return
            }
            
            self.semaphore.wait()
            
            guard !isCancelled else {
                return
            }
            
            self.error = error
            self.cancelAllOperations()
        }
    }
    
    private func successBlock<T>(in operation: LKAsyncSequenceOperation<T>) -> ((T) -> Void)  {
        return { [weak self, weak operation] (object: T) in
            
            guard let self = self,
                  let identifier = operation?.identifier,
                  operation?.isCancelled == false
            else {
                return
            }
            
            self.writeIntoSuccessResult(with: identifier, and: object)
        }
    }
    
    private func fetchFromSuccessResult() -> [AnyHashable: Any] {
        resultQueue.sync {
            _successResult
        }
    }
    
    private func writeIntoSuccessResult(with key: AnyHashable, and value: Any) {
        resultQueue.sync(flags: .barrier) {
            _successResult[key] = value
        }
    }
    
    private func setSuccessResultToEmpty() {
        resultQueue.sync(flags: .barrier) {
            _successResult = [:]
        }
    }
    
    public func addAsyncOperation<T>(_ operation: LKAsyncSequenceOperation<T>) {
        let op = operation
            .finished(self.finishedBlock(for: operation))
            .failure(self.failureBlock(in: operation))
            .success(self.successBlock(in: operation))
        
        ops.append(op)
    }
    
    public func runOperationsConcurrently() {
        for op in ops {
            group.enter()
            op.prepareToExecute()
            super.addOperation(op)
        }
        
        ops.removeAll()

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if let error = self.error {
                self.completionBlock(.failure(error))
            } else {
                self.completionBlock(.success((self.fetchFromSuccessResult())))
            }
            self.setSuccessResultToEmpty()
        }
    }
    
    public func runOperationsSerially() {
        for i in 1 ..< ops.count {
            let previousOperation = ops[i-1]
            let nextOperation = ops[i]
            nextOperation.addDependency(previousOperation)
        }

        runOperationsConcurrently()
    }
    
    @discardableResult
    public func completion(_ block: @escaping AsyncCompletionBlock) -> Self {
        self.completionBlock = block
        return self
    }
    
    deinit {
        print("==== \(type(of: self)) operation queue deinit ====.")
    }
}
