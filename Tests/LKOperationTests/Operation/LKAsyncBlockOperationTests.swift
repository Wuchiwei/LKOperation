//
//  File.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/15.
//

import Foundation
import XCTest
@testable import LKOperation

class LKAsyncBlockOperationTest: XCTestCase {
    
    var queue: OperationQueue!
    
    override func setUp() {
        super.setUp()
        queue = OperationQueue()
    }
    
    func makeSut(
        block: @escaping ((LKAsyncBlockOperation) -> Void) = { _ in }
    ) -> LKAsyncBlockOperation {
        
        let op = LKAsyncBlockOperation(block)
        op.prepareToExecute()
        
        return op
    }
    
    func test_execute_blockShouldBeInvokeWhenAddOperationToQueue() {
        
        //Give
        let expectation = expectation(description: "Expect to be invoked")
        let sut = makeSut(block: { op in
            expectation.fulfill()
        })
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
    }
    
    func test_execute_operationPassInBlockShouldBeEqualToSut() {
        
        //Give
        let expectation = expectation(description: "Expect to be invoked")
        var experimentalResult: LKAsyncBlockOperation?
        
        let sut = makeSut(block: { op in
            expectation.fulfill()
            experimentalResult = op
        })
        
        let expectResult = sut
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
        XCTAssertNotNil(experimentalResult)
        XCTAssertEqual(experimentalResult!, expectResult)
    }
    
    func test_execute_blockMethodShouldReplaceTheInitialBlock() {
        //Give
        let expectation = expectation(description: "Expect to be invoked")
        var experimentalResult: LKAsyncBlockOperation?
        
        let sut = makeSut()
        sut.block{ op in
            experimentalResult = op
            expectation.fulfill()
        }
        
        let expectResult = sut
        
        //When
        queue.addOperation(sut)
        
        //Then
        wait(for: [expectation], timeout: 3)
        XCTAssertNotNil(experimentalResult)
        XCTAssertEqual(experimentalResult!, expectResult)
    }
    
    func test_execute_blockMethodShouldReturnTheSameOperation() {
        //Give
        
        let sut = makeSut()
        let experimentalResult = sut.block{ _ in }
        
        let expectResult = sut
        
        //When
        
        
        //Then
        XCTAssertEqual(experimentalResult, expectResult)
    }
}
