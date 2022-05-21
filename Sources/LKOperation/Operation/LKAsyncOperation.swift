//
//  LKAsyncOperation.swift
//
//  Created by WU CHIH WEI on 2022/5/11.
//

import Foundation

/// LKAsyncOperation has the following responsibilities
///
/// 1. Use private property state to manage properties with prefix keyword 'is'(ex: isReady, isExecuting, etc.). We can use state(_:) and state() method to change and retrive state of operation.
///
///  - The idea of design is due to these properties inhirint from NSOperation, and these are read-only properties. Operation Queue execute operation depend on these properties with KVO mechanism.
///  - Every time we change state, the operation will trigger KVO's willChangeValue and didChangeValue method to trigger KVO. This make our LKAsyncOperation work ferfectly with operation queue.
///
/// 2.prepareToExecute() method will change state from initial value .pending to .ready. The operation queue know this operation is ready when we change the state to ready and it will put the operation into avaliable therad for executing
///
/// 3. In the start() method we check the isCancelled property. If the operation is cancelled, we change the state to .finished, otherwise we change the state to .executing and invoke main() method.
///
///4. In main method, we invoke testBlock closure for testing purpose. Subclass should override main method for putting their task here.
///
///
///- warning: Do not use this class directly. There is AsyncBlockOperation class you can use for implemete async operation block. Or subclass and put your implemetation inside main() method.

open class LKAsyncOperation: Operation {
    
    public enum State: String {
        
        case ready, executing, finished, pending
        
        fileprivate var keyPath: String { "is\(rawValue.capitalized)" }
    }
    
    public let identifier: UUID = UUID()
    
    public override var isReady: Bool { super.isReady && _state == .ready }
    
    public override var isAsynchronous: Bool { true }
    
    public override var isExecuting: Bool { _state == .executing }
    
    public override var isFinished: Bool { _state == .finished }
    
    public var isPending: Bool { _state == .pending }
    
    private let queue = DispatchQueue(
        label: UUID().uuidString,
        attributes: .concurrent
    )
    
/// Use private property state to manage properties with prefix keyword 'is'(ex: isReady, isExecuting, etc.). We can use state(_:) and state() method to change and retrive state of operation.
///
///  - The idea of design is due to these properties inhirint from NSOperation, and these are read-only properties. Operation Queue execute operation depend on these properties with KVO mechanism.
///  - Every time we change state, the operation will trigger KVO's willChangeValue and didChangeValue method to trigger KVO. This make our LKAsyncOperation work ferfectly with operation queue.
    
    private var _state: State = .pending {
        willSet {
            willChangeValue(forKey: _state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }

        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: _state.keyPath)
        }
    }
    
    private var testBlock: () -> Void = {}
    
    public convenience override init() {
        self.init(test: {})
    }
    
    init(test testBlock: @escaping () -> Void) {
        self.testBlock = testBlock
        super.init()
    }
    
/// In the start() method we check the isCancelled property. If the operation is cancelled, we change the state to .finished, otherwise we change the state to .executing and invoke main() method.
    public override func start() {
        guard !isCancelled else {
            setState(.finished)
            return
        }
        setState(.executing)
        main()
    }
    
    ///In main method, we invoke testBlock closure for testing purpose.
    ///Subclass should override this method to implement async task inside the method.
    open override func main() {
        
        testBlock()
    }
    
    public func state() -> State {
        queue.sync {
            _state
        }
    }
    
    public func setState(_ value: State) {
        queue.sync(flags: .barrier) { [weak self] in
            self?._state = value
        }
    }
    
    ///prepareToExecute() method will change state from initial value .pending to .ready. The operation queue know this operation is ready when we change the state to ready and it will put the operation into avaliable therad for executing
    
    public func prepareToExecute() {
        setState(.ready)
    }
    
    ///Sytax sugur. Add the operation as dependency and reture self for futhur work
    
    @discardableResult
    public func lk_addDependency(_ op: Operation) -> Self {
        super.addDependency(op)
        return self
    }
    
    deinit {
        print("==== \(type(of: self)) operation deinit ====.")
    }
}
