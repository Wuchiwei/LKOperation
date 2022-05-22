//
//  LKAsyncOperationTests.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/14.
//

import XCTest
@testable import LKOperation

class LKAsyncOperationTests: XCTestCase {
    
    func makeSut(testBlock: @escaping () -> Void = {}) -> LKAsyncOperation {
        return LKAsyncOperation(test: testBlock)
    }
    
    func test_initialValueOfState_shouldBePending() {
        //Give
        let sut = makeSut()
        //When
        let experimentalResult = sut.state()
        let expectResult = LKAsyncOperation.State.pending
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The initial value of state property in an LKAsyncOperation should be pending"
        )
    }
    
    func test_valueOfComputerProperties_initialValueOfProperties() {
        //Give
        let sut = makeSut()
        //When
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: false,
            isExecuted: false,
            isFinished: false,
            isAsynchronous: true,
            isPending: true
        )
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of computer properties in an LKAsyncOperation should equal to expected result"
        )
    }
    
    func test_valueOfComputerProperties_stateChangeToReady() {
        //Give
        let sut = makeSut()
        //When
        sut.setState(.ready)
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: true,
            isExecuted: false,
            isFinished: false,
            isAsynchronous: true,
            isPending: false
        )
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of computer properties in an LKAsyncOperation should equal to expected result"
        )
    }
    
    func test_valueOfComputerProperties_stateChangeToExecuting() {
        //Give
        let sut = makeSut()
        //When
        sut.setState(.executing)
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: false,
            isExecuted: true,
            isFinished: false,
            isAsynchronous: true,
            isPending: false
        )
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of computer properties in an LKAsyncOperation should equal to expected result"
        )
    }
    
    func test_valueOfComputerProperties_stateChangeToFinished() {
        //Give
        let sut = makeSut()
        //When
        sut.setState(.finished)
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: false,
            isExecuted: false,
            isFinished: true,
            isAsynchronous: true,
            isPending: false
        )
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of computer properties in an LKAsyncOperation should equal to expected result"
        )
    }

    func test_state_prepareToExecute_stateShouldBeReady() {
        //Give
        let sut = makeSut()
        //When
        sut.prepareToExecute()
        let experimentalResult = sut.state()
        let expectResult = LKAsyncOperation.State.ready
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of state in an LKAsyncOperation should equal to expected result"
        )
    }
    
    func test_valueOfComputerProperties_prepareToExecute() {
        //Give
        let sut = makeSut()
        //When
        sut.prepareToExecute()
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: true,
            isExecuted: false,
            isFinished: false,
            isAsynchronous: true,
            isPending: false
        )
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of computer properties in an LKAsyncOperation should equal to expected result"
        )
    }
    
    func test_execution_setState_stateShouldEqualToNewValue() {
        //Give
        let sut = makeSut()
        let input = LKAsyncOperation.State.finished
        let initialResult = sut.state()
        
        //When
        sut.setState(input)
        let experimentalResult = sut.state()
        let expectResult = input
        
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of state property should equal to executing."
        )
        
        XCTAssertNotEqual(
            initialResult,
            input,
            "The value of state property should not equal to input value."
        )
    }
    
    func test_execution_testBlock_shouldBeExecuteWhenOperationStart() {
        //Give
        let expectation = expectation(description: "Main method invoked")
        let input = {
            expectation.fulfill()
        }
        let sut = makeSut(testBlock: input)
        
        //When
        sut.start()
        
        //Then
        wait(for: [expectation], timeout: 3)
    }
    
    func test_execution_sendCancelMessageToOperationAndRunStart_stateShouldChangeToFinished() {
        //Give
        let sut = makeSut()
        
        //When
        sut.cancel()
        sut.start()
        
        let expectResult = LKAsyncOperation.State.finished
        let experimentalResult = sut.state()
        
        //Then
        XCTAssertEqual(
            expectResult,
            experimentalResult,
            "State should be finished when operation get cancelled before start."
        )
    }
    
    func test_execution_sendCancelMessageToOperationAndRunStart_finishedKVOShouldSendMessage() {
        //Give
        let sut = makeSut()
        let finishedObserverExpectation = expectation(description: "Finished property kvo invoke")
        
        //When
        let finishedObservation = sut.observe(
            \.isFinished,
             options: [.new],
             changeHandler: { operation, changes in
                 finishedObserverExpectation.fulfill()
             }
        )
        //When
        sut.cancel()
        sut.start()
        
        //Then
        wait(for: [finishedObserverExpectation], timeout: 3)
        finishedObservation.invalidate()
    }
    
    func test_execution_sendCancelMessageToOperationAndRunStart_testBlockShouldNotBeExecuted() {
        //Give
        //result property could be any reference type, here we take Operation as example
        var result: Operation?
        let input = {
            result = Operation()
        }
        let sut = makeSut(testBlock: input)
        
        //When
        sut.cancel()
        sut.start()
        
        //Then
        XCTAssertNil(
            result,
            "Test block should not be invoked when operaion is cancelled before start."
        )
    }
    
    func test_execution_addOperationToQeueuWithoutPrepareToEcecute_operationShouldNotBeInvoke() {
        //Give
        var isInvoked: Bool = false
        let sut = makeSut(testBlock: {
            isInvoked = true
        })
        let queue = OperationQueue()
        
        //When
        queue.addOperation(sut)
        
        //Then
        sleep(3)
        XCTAssertFalse(isInvoked)
    }
    
    func test_execution_addOperationToQeueuWithPrepareToEcecute_KVONotificationShouldSendMessageToObserver() {
        //Give
        let sut = makeSut()
        sut.prepareToExecute()
        let queue = OperationQueue()
        let readyObserverExpectation = expectation(description: "Ready property kvo invoke")
        let executingObserverExpectation = expectation(description: "Executing property kvo invoke")
        
        //When
        var isReady: Bool? = true
        let readyObservation = sut.observe(
            \.isReady,
             options: [.new],
             changeHandler: { operation, changes in
                 readyObserverExpectation.fulfill()
                 isReady = changes.newValue
             }
        )
        
        var isExecuting: Bool? = false
        let executingObservation = sut.observe(
            \.isExecuting,
             options: [.new],
             changeHandler: { operation, changes in
                 executingObserverExpectation.fulfill()
                 isExecuting = changes.newValue
             }
        )
        
        queue.addOperation(sut)
        
        //Then
        wait(
            for: [
                readyObserverExpectation,
                executingObserverExpectation
            ],
            timeout: 3
        )
        
        XCTAssertNotNil(isReady)
        XCTAssertNotNil(isExecuting)
        
        XCTAssertFalse(isReady!)
        XCTAssertTrue(isExecuting!)
        
        readyObservation.invalidate()
        executingObservation.invalidate()
    }
    
    func test_execution_prepareToExecute_KVONotificationShouldSendMessageToObserver() {
        //Give
        let sut = makeSut()
        let readyObserverExpectation = expectation(description: "Ready property kvo invoke")
        
        //When
        
        var experimentalResult: Bool?
        let readyObservation = sut.observe(
            \.isReady,
             options: [.new],
             changeHandler: { operation, changes in
                 experimentalResult = changes.newValue
                 readyObserverExpectation.fulfill()
             }
        )
        
        sut.prepareToExecute()
        //Then
        wait(
            for: [
                readyObserverExpectation,
            ],
            timeout: 3
        )
        
        XCTAssertNotNil(experimentalResult)
        XCTAssertTrue(experimentalResult!)
        readyObservation.invalidate()
    }
    
    func test_value_identifierShouldNotBeEqualBetweenTwoOperation() {
        //Give
        let sut1 = makeSut()
        let sut2 = makeSut()
        //When
        
        //Then
        XCTAssertNotEqual(sut1.identifier, sut2.identifier)
    }
    
    func test_execute_lk_addDependency_shouldReturnTheSameOperation() {
        
        //Give
        let sut = makeSut()
        let op = Operation()
        
        //When
        let experimentalResult = sut.lk_addDependency(op)
        let expectResult = sut
        
        //Then
        XCTAssertEqual(experimentalResult, expectResult)
    }
    
    func test_execute_lk_addDependency_shouldAddDependency() {
        
        //Give
        let sut = makeSut()
        let op = Operation()
        
        //When
        sut.lk_addDependency(op)
        let experimentalResult = sut.dependencies
        let expectResult = [op]
        
        //Then
        XCTAssertEqual(experimentalResult, expectResult)
    }
}
