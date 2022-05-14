//
//  AsyncOperation.swift
//
//  Created by WU CHIH WEI on 2022/5/11.
//

import Foundation

///Abstract Class. Conform this class to get async operation state management ability.
///
///Manipulate the `state` preperty to manage the KVO relative property inherints from Operation class.
///When you change the `state` property will trigger the KVO notification to notify properties observers.
///- warning: Do not use this class directly. There is AsyncBlockOperation class you can use for implemete async operation block
///
///Even we do barrier scenario for achieving thread safe, but AsyncOperation is still not thread safe. We can't block any property associated with state property when we are changing state property (ex: isReady computer property). Please use AsyncOperation carefully with multithread accessing.

open class LKAsyncOperation: Operation {
    
    public enum State: String {
        
        case ready, executing, finished
        
        fileprivate var keyPath: String { "is\(rawValue.capitalized)" }
    }
    
    private let queue = DispatchQueue(
        label: UUID().uuidString,
        attributes: .concurrent
    )
    
    private var _state: State = .ready {
        willSet {
            willChangeValue(forKey: _state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }

        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: _state.keyPath)
        }
    }
    
    public override var isReady: Bool { super.isReady && _state == .ready }
    
    public override var isAsynchronous: Bool { true }
    
    public override var isExecuting: Bool { _state == .executing }
    
    public override var isFinished: Bool { _state == .finished }
    
    ///completeBlock closure will be called when operation is cancelled before main() method has executed.
    ///
    ///If you need do something when operation is cancelled, you can add it in completeBlock through complete(:_) method.
    ///
    ///In your implementation of async task, you should call completeBlock when your task is finished or is quit from the process.
    public private(set) lazy var completeBlock: () -> Void = { [weak self] in
        guard let self = self else { return }
        self.setState(.finished)
    }
    
    private var testBlock: () -> Void = {}
    
    public convenience override init() {
        self.init(test: {})
    }
    
    init(test testBlock: @escaping () -> Void) {
        self.testBlock = testBlock
        super.init()
    }
    
    public override func start() {
        guard !isCancelled else {
            completeBlock()
            return
        }
        setState(.executing)
        main()
    }
    
    ///Subclass should override this method to implement async task
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
    
    public func complete(_ block: @escaping () -> Void) -> Self {
        self.completeBlock = { [weak self] in
            guard let self = self else { return }
            block()
            self.setState(.finished)
        }
        return self
    }
}
