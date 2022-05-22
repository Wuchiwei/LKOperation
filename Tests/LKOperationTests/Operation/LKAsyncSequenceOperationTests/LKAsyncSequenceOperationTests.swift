//
//  LKAsyncSequenceOperationTests.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/22.
//

import XCTest
@testable import LKOperation

class LKAsyncSequenceOperationTests: LKAsyncOperationTests {
    
    enum TestError: Error {
        case test
    }
    
    var queue: OperationQueue!
    
    override func setUp() {
        super.setUp()
        
        queue = OperationQueue()
    }
    
    override func makeSut(testBlock: @escaping () -> Void = {}) -> LKAsyncOperation {
        
        return LKAsyncSequenceOperation(
            { (controller: LKBlockController<Int>) in
            
            },
            testBlock: testBlock
        )
    }
    
    func makeSequenceOperationSut<T>(
        controller: @escaping (LKBlockController<T>) -> Void
    ) -> LKAsyncSequenceOperation<T> {
        
        let op = LKAsyncSequenceOperation(controller)
        op.prepareToExecute()
        return op
    }
    
    // MARK: - block should be invoked when op is ready and put in to operation queue
    func test_blockPassThroughInitializer_shouldBeInvoked() {
        //Give
        let expectation = expectation(description: "Expect block to be invoked")
        let block = { (controller: LKBlockController<Int>) in
            expectation.fulfill()
        }
        
        //When
        let sut = makeSequenceOperationSut(controller: block)
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
    }
    
    func test_blockPassThroughMethod_shouldBeInvoked() {
        //Give
        let expectation = expectation(description: "Expect block to be invoked")
        let block = { (controller: LKBlockController<Int>) in
            expectation.fulfill()
        }
        
        //When
        let sut = makeSequenceOperationSut(
            controller: { (controller: LKBlockController<Int>) in
            
            }
        )
        
        sut.block(block)
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
    }
    
    // MARK: - 透過 method 放進去的 closure 可以在 block 裡面被執行
    func test_value_successBlockShouldBeInvokedByControllerSuccessBlock() {
        //Give
        var experimentalResult = 0
        let expectation = expectation(description: "Expect to be invoked")
        let successBlock: (Int) -> Void = { input in
            experimentalResult = input
            expectation.fulfill()
        }
        
        let expectResult = 10
        
        let sut = makeSequenceOperationSut(
            controller: { (controller: LKBlockController<Int>) in
                controller.success(expectResult)
            }
        )
        
        sut.success(successBlock)
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
        XCTAssertEqual(experimentalResult, expectResult)
    }
    
    func test_value_failureBlockShouldBeInvokedByControllerFailureBlock() {
        //Give
        var experimentalResult: Error?
        let expectation = expectation(description: "Expect to be invoked")
        let failureBlock: (Error) -> Void = { input in
            experimentalResult = input
            expectation.fulfill()
        }
        
        let expectResult = TestError.test
        
        let sut = makeSequenceOperationSut(
            controller: { (controller: LKBlockController<Int>) in
                controller.failure(expectResult)
            }
        )
        
        sut.failure(failureBlock)
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
        XCTAssertNotNil(experimentalResult)
        XCTAssertEqual(experimentalResult as? TestError, expectResult)
    }
    
    func test_value_finishedBlockShouldBeInvokedByControllerFinishBlock() {
        //Give
        var experimentalResult = false
        let expectation = expectation(description: "Expect finished block to be invoked")
        let finishedBlock: (Bool) -> Void = { input in
            experimentalResult = input
            expectation.fulfill()
        }
        
        let expectResult = true
        let sut = makeSequenceOperationSut(
            controller: { (controller: LKBlockController<Int>) in
                controller.finished(expectResult)
            }
        )
        
        sut.finished(finishedBlock)
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
        XCTAssertEqual(experimentalResult, expectResult)
    }
    
    func test_value_controllerIsCancellBlockReturnValue_ShouldEqualToOperationIsCancellProperty() {
        //Give
        var experimentalResult: Bool?
        let expectation = expectation(description: "Expect finished block to be invoked")
        
        let sut = makeSequenceOperationSut(
            controller: { (controller: LKBlockController<Int>) in
                experimentalResult = controller.isCancelled()
                expectation.fulfill()
            }
        )
        
        //When
        queue.addOperation(sut)
        let expectResult = sut.isCancelled
        
        //Then
        wait(for: [expectation], timeout: 3)
        XCTAssertEqual(experimentalResult, expectResult)
    }
    
    // MARK: - result property should be failure if controller failure block invoked
    func test_controllerFailureBlockBeInvoked_resultShouldBeFailure() {
        //Give
        let expectation = expectation(description: "Expect to be invoked")
        let expectResult = TestError.test
        
        let sut = makeSequenceOperationSut(
            controller: { (controller: LKBlockController<Int>) in
                controller.failure(expectResult)
                expectation.fulfill()
            }
        )
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
        
        switch sut.result {
        case .failure(let error):
            XCTAssertEqual(error as? TestError, TestError.test)
        case .success:
            XCTFail("Result should not be success case")
        case nil:
            XCTFail("Result should not be nil")
        }
    }
    
    // MARK: - result property should be success if controller success block invoked
    func test_controllerSuccessBlockBeInvoked_resultShouldBeSuccess() {
        //Give
        let expectation = expectation(description: "Expect to be invoked")
        let expectResult = 10
        
        let sut = makeSequenceOperationSut(
            controller: { (controller: LKBlockController<Int>) in
                controller.success(expectResult)
                expectation.fulfill()
            }
        )
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
        
        switch sut.result {
        case .failure:
            XCTFail("Result should not be failure case")
        case .success(let value):
            XCTAssertEqual(value, expectResult)
        case nil:
            XCTFail("Result should not be nil")
        }
    }
    
    // MARK - 如果取消則不會被執行 closure，state 必須 ture to finish
    func test_cancelOperation_blockClosureShouldNotBeInvoked() {
        //Give
        var experimentalResult: Bool = false
        let block = { (controller: LKBlockController<Int>) in
            experimentalResult = true
        }
        let sut = makeSequenceOperationSut(controller: block)
        
        //When
        sut.cancel()
        queue.addOperation(sut)
        
        //Then
        sleep(3)
        XCTAssertFalse(experimentalResult)
        XCTAssertEqual(sut.state(), LKAsyncOperation.State.finished)
    }
    
    func test_cancelOperationAndRunStart_stateShouldChangeToFinished() {
        //Give
        let block = { (controller: LKBlockController<Int>) in
            
        }
        let sut = makeSequenceOperationSut(controller: block)
        
        //When
        sut.cancel()
        sut.start()
        
        //Then
        XCTAssertEqual(sut.state(), LKAsyncOperation.State.finished)
    }
    
    // MARK: - addto(queue:)
    func test_addtoMethod_shouldInvokeOperationQueueAddAsyncOperationMethod() {
        //Give
        let mockQueue = MockLKAsyncSequenceOperationQueue()
        let block = { (controller: LKBlockController<Int>) in
            
        }
        let sut = makeSequenceOperationSut(controller: block)
        
        //When
        sut.addTo(queue: mockQueue)
        
        //Then
        XCTAssertEqual(sut, mockQueue.operation)
    }
}
