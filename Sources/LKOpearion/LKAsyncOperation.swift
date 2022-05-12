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

class LKAsyncOperation: Operation {
    
    enum State: String {
        
        case ready, executing, finished
        
        fileprivate var keyPath: String { "is\(rawValue.capitalized)" }
    }
    
    private let queue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
    
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
    
    override var isReady: Bool { super.isReady && _state == .ready }
    
    override var isAsynchronous: Bool { true }
    
    override var isExecuting: Bool { _state == .executing }
    
    override var isFinished: Bool { _state == .finished }
    
    private(set) var completeBlock: () -> Void = { }
    
    override func start() {
        guard !isCancelled else {
            setState(.finished)
            completeBlock()
            return
        }
        setState(.executing)
        main()
    }
    
    func state() -> State {
        queue.sync {
            _state
        }
    }
    
    func setState(_ value: State) {
        queue.async(flags: .barrier) { [weak self] in
            self?._state = value
        }
    }
    
    func complete(_ completeBlock: @escaping () -> Void) -> Self {
        self.completeBlock = completeBlock
        return self
    }
}
