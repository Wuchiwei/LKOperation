//
//  LKAsyncOperationTests.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/14.
//

import XCTest
@testable import LKOpearion

class LKAsyncOperationTests: XCTestCase {
    
    func makeSut(testBlock: @escaping () -> Void = {}) -> LKAsyncOperation {
        return LKAsyncOperation(test: testBlock)
    }
    
    func test_value_initialValueOfState_shouldBeReady() {
        //Give
        let sut = makeSut()
        //When
        let experimentalResult = sut.state()
        let expectResult = LKAsyncOperation.State.ready
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The initial value of state property in an LKAsyncOperation should be ready"
        )
    }
    
    func test_value_initialValueOfProperties() {
        //Give
        let sut = makeSut()
        //When
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: true,
            isExecuted: false,
            isFinished: false,
            isAsynchronous: true
        )
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of computer properties in an LKAsyncOperation should equal to expected result"
        )
    }
    
    func test_value_changeStateToExecuting_propertyValueShouldMappingToNewState() {
        //Give
        let sut = makeSut()
        let input = LKAsyncOperation.State.executing
        //When
        sut.setState(input)
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: false,
            isExecuted: true,
            isFinished: false,
            isAsynchronous: true
        )
        //Then
        XCTAssertEqual(
            experimentalResult,
            expectResult,
            "The value of computer properties in an LKAsyncOperation should equal to expected result"
        )
    }
    
    func test_value_changeStateToFinished_propertyValueShouldMappingToNewState() {
        //Give
        let sut = makeSut()
        let input = LKAsyncOperation.State.finished
        //When
        sut.setState(input)
        let experimentalResult = OperationPropertyCollector.object(with: sut)
        let expectResult = OperationPropertyCollector(
            isReady: false,
            isExecuted: false,
            isFinished: true,
            isAsynchronous: true
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
    
    func test_execution_sendCancelMessageToOperationAndRunStart_completionBlockShouldBeInvoke() {
        //Give
        let expectation = expectation(description: "Complete block invoked")
        let sut = makeSut().complete {
            expectation.fulfill()
        }
        
        //When
        sut.cancel()
        sut.start()
        
        //Then
        wait(for: [expectation], timeout: 3)
    }
    
    func test_execution_changeState_KVONotificationShouldSendMessageToObserver() {
        //Give
        let sut = makeSut()
        let queue = OperationQueue()
        let readyObserverExpectation = expectation(description: "Ready property kvo invoke")
        let executingObserverExpectation = expectation(description: "Executing property kvo invoke")
        
        //When
        let readyObservation = sut.observe(
            \.isReady,
             options: [.new],
             changeHandler: { operation, changes in
                 readyObserverExpectation.fulfill()
             }
        )
        
        let executingObservation = sut.observe(
            \.isExecuting,
             options: [.new],
             changeHandler: { operation, changes in
                 executingObserverExpectation.fulfill()
             }
        )
        
        //Then
        queue.addOperation(sut)
        wait(
            for: [
                readyObserverExpectation,
                executingObserverExpectation
            ],
            timeout: 3
        )
        
        readyObservation.invalidate()
        executingObservation.invalidate()
    }
}
