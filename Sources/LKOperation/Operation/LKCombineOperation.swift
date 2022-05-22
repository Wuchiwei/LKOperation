//
//  CombineOperation.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/21.
//

import Foundation

public enum LKCombineOperationError: Error {
    case unknowed
}

public class LKCombineOperation<A, B>: LKAsyncOperation {
    
    private let a: LKAsyncSequenceOperation<A>
    
    private let b: LKAsyncSequenceOperation<B>
    
    private let finishedBlock: (Result<(A, B), Error>?) -> Void
    
    public init(
        _ a: LKAsyncSequenceOperation<A>,
        _ b: LKAsyncSequenceOperation<B>,
        finishedBlock: @escaping (Result<(A, B), Error>?) -> Void
    ) {
        self.a = a
        self.b = b
        self.finishedBlock = finishedBlock
        super.init(test: {})
        
        addDependency(a)
        addDependency(b)
    }
    
    public override func main() {

        guard !a.isCancelled && !b.isCancelled && !isCancelled else {
            cancel()
            setState(.finished)
            finishedBlock(nil)
            return
        }

        switch (a.result, b.result) {
        case (.success(let aObject), .success(let bObject)):
            finishedBlock(.success((aObject, bObject)))
        case (.failure(let error), _):
            finishedBlock(.failure(error))
        case (_, .failure(let error)):
            finishedBlock(.failure(error))
        default: finishedBlock(.failure(LKCombineOperationError.unknowed))
        }

        setState(.finished)
    }

    public func addTo(queue: OperationQueue) {
        queue.addOperation(self)
        queue.addOperation(a)
        queue.addOperation(b)
    }

    public override func prepareToExecute() {
        super.prepareToExecute()
        a.prepareToExecute()
        b.prepareToExecute()
    }
}
