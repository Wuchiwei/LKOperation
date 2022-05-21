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

public class LKCombineOperation<A, B>: LKAsyncSequenceOperation<(A, B)> {
    
    private let a: LKAsyncSequenceOperation<A>
    
    private let b: LKAsyncSequenceOperation<B>
    
    public init(_ a: LKAsyncSequenceOperation<A>, _ b: LKAsyncSequenceOperation<B>) {
        self.a = a
        self.b = b
        super.init()
        
        a.finished { [weak self] _ in
            self?.b.cancel()
        }
        
        b.finished { [weak self] _ in
            self?.a.cancel()
        }
        
        addDependency(a)
        addDependency(b)
    }
    
    public override func main() {
        guard !a.isCancelled || !b.isCancelled else {
            finishedBlock(true)
            return
        }
        
        switch (a.result, b.result) {
        case (.success(let aObject), .success(let bObject)):
            successBlock((aObject, bObject))
        case (.failure(let error), _):
            failureBlock(error)
        case (_, .failure(let error)):
            failureBlock(error)
        default: failureBlock(LKCombineOperationError.unknowed)
        }
        
        finishedBlock(false)
    }
    
    public override func addTo(queue: LKAsyncSequenceOperationQueue) {
        a.addTo(queue: queue)
        b.addTo(queue: queue)
        super.addTo(queue: queue)
    }
}
