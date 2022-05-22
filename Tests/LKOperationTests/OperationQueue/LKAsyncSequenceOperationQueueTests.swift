//
//  File.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/22.
//

import Foundation
import XCTest
@testable import LKOperation

class LKAsyncSequenceOperationQueueTests: XCTestCase {
    
    enum TestError: Error {
        case test
    }
    
    func makeSut() -> LKAsyncSequenceOperationQueue {
        return LKAsyncSequenceOperationQueue()
    }
    
    func makeOperation<T>() -> LKAsyncSequenceOperation<T> {
        let op = LKAsyncSequenceOperation<T>()
        op.prepareToExecute()
        return op
    }
    
    func test_addAsyncOperation_shouldSaveOperationToOpsArray() {
        //Give
        let op = LKAsyncSequenceOperation<Int>{ _ in }
        let sut = makeSut()
        
        //When
        sut.addAsyncOperation(op)
        
        //Then
        XCTAssertEqual(sut.ops, [op])
    }
    
    func test_runOperationSerially() {
        //Give
        let op1: LKAsyncSequenceOperation<Int> = makeOperation()
        let op2: LKAsyncSequenceOperation<Int> = makeOperation()
        let sleepInterval1: UInt32 = 1
        let sleepInterval2: UInt32 = 2
        
        var op1FinishedTime: Double?
        var op2FinishedTime: Double?
        var totalFinishedTime: Double?
        
        let expectation1 = expectation(description: "op1 should be executed")
        let expectation2 = expectation(description: "op2 should be executed")
        
        op1.block{ controller in
            sleep(sleepInterval1)
            op1FinishedTime = Date().timeIntervalSince1970
            controller.finished(false)
            expectation1.fulfill()
        }
        
        op2.block{ controller in
            sleep(sleepInterval2)
            op2FinishedTime = Date().timeIntervalSince1970
            controller.finished(false)
            expectation2.fulfill()
        }
        
        let sut = makeSut()
        
        sut.completion{ _ in
            totalFinishedTime = Date().timeIntervalSince1970
        }
        //When
        sut.addAsyncOperation(op1)
        sut.addAsyncOperation(op2)
        let startTime = Date().timeIntervalSince1970
        print(sut.ops.count)
        sut.runOperationsSerially()
        
        //Then
        wait(for: [expectation1, expectation2], timeout: 6)
        
        if let op1FinishedTime = op1FinishedTime,
           let op2FinishedTime = op2FinishedTime,
           let totalFinishedTime = totalFinishedTime
        {
            XCTAssertTrue(op2FinishedTime > op1FinishedTime)
            XCTAssertTrue(totalFinishedTime - startTime > Double(sleepInterval1 + sleepInterval2), "\(totalFinishedTime), \(startTime)")
            
        } else {
            XCTFail("op1FinishedTime or op2FinishedTime or totalFinishedTime should not be nil")
        }
    }
    
    func test_runOperationsConcurrently() {
        //Give
        let op1: LKAsyncSequenceOperation<Int> = makeOperation()
        let op2: LKAsyncSequenceOperation<Int> = makeOperation()
        let sleepInterval1: UInt32 = 1
        let sleepInterval2: UInt32 = 2
        
        var totalFinishedTime: Double?
        
        let expectation = expectation(description: "Complet block should be executed")
        
        op1.block{ controller in
            
            sleep(sleepInterval1)
            controller.finished(false)
        }
        
        op2.block{ controller in
            
            sleep(sleepInterval2)
            controller.finished(false)
        }
        
        let sut = makeSut()
        
        sut.completion{ _ in
            totalFinishedTime = Date().timeIntervalSince1970
            expectation.fulfill()
        }
        //When
        sut.addAsyncOperation(op1)
        sut.addAsyncOperation(op2)
        let startTime = Date().timeIntervalSince1970
        sut.runOperationsConcurrently()
        
        //Then
        wait(for: [expectation], timeout: 3)
        
        if let totalFinishedTime = totalFinishedTime
        {
            
            XCTAssertTrue(totalFinishedTime - startTime < Double(sleepInterval1 + sleepInterval2), "\(totalFinishedTime), \(startTime)")
            
        } else {
            XCTFail("totalFinishedTime should not be nil")
        }
    }
    
    func test_completionBlock_shouldInvokeWithError() {
        //Give
        let op1: LKAsyncSequenceOperation<Int> = makeOperation()
        let op2: LKAsyncSequenceOperation<Int> = makeOperation()
        
        let expectation = expectation(description: "Complet block should be executed")
        let expectResult = TestError.test
        
        op1.block{ controller in
            
            controller.failure(expectResult)
            controller.finished(false)
        }
        
        op2.block{ controller in
            
            controller.success(10)
            controller.finished(false)
        }
        
        let sut = makeSut()
        
        var experimentalResult: Result<[AnyHashable : Any], Error>?
        
        sut.completion{ result in
            experimentalResult = result
            expectation.fulfill()
        }
        //When
        sut.addAsyncOperation(op1)
        sut.addAsyncOperation(op2)
        sut.runOperationsConcurrently()
        
        //Then
        wait(for: [expectation], timeout: 3)
        
        switch experimentalResult {
        case .failure(let error):
            XCTAssertEqual(error as? TestError, expectResult)
        default:
            XCTFail("Result should be failure event.")
        }
    }
    
    func test_completionBlock_shouldInvokeWithSuccess() {
        //Give
        let op1: LKAsyncSequenceOperation<Int> = makeOperation()
        let op2: LKAsyncSequenceOperation<String> = makeOperation()
        
        let expectation = expectation(description: "Complet block should be executed")
        let expectResultOfOp1 = 10
        let expectResultOfOp2 = "A"
        
        op1.block{ controller in
                controller.success(expectResultOfOp1)
                controller.finished(false)
        }
        
        op2.block{ controller in
                controller.success(expectResultOfOp2)
                controller.finished(false)
        }
        
        let sut = makeSut()
        
        var experimentalResult: Result<[AnyHashable : Any], Error>?
        
        sut.completion{ result in
            experimentalResult = result
            expectation.fulfill()
        }
        //When
        sut.addAsyncOperation(op1)
        sut.addAsyncOperation(op2)
        sut.runOperationsConcurrently()
        
        //Then
        wait(for: [expectation], timeout: 3)
        
        switch experimentalResult {
        case .success(let data):
            XCTAssertEqual(data[op1.identifier] as? Int, expectResultOfOp1)
            XCTAssertEqual(data[op2.identifier] as? String, expectResultOfOp2)
        default:
            XCTFail("Result should be success event.")
        }
    }
    
    func test_raceCondition() {
        for _ in 0...10000 {
            test_completionBlock_shouldInvokeWithSuccess()
        }
    }
}
