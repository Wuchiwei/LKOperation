//
//  LKAsyncBlockOperationTests.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/15.
//

import Foundation
import XCTest
@testable import LKOperation

class LKAsyncBlockOperationTests: LKAsyncOperationTests {
    
    var queue: OperationQueue!
    
    override func setUp() {
        super.setUp()
        queue = OperationQueue()
    }
    
    override func makeSut(
        testBlock: @escaping () -> Void = {}
    ) -> LKAsyncOperation {
        return LKAsyncBlockOperation(
            { _ in },
            testBlock: testBlock
        )
    }
    
    func makeBlockOperationSut(
        block: @escaping ((LKAsyncBlockOperation) -> Void) = { _ in }
    ) -> LKAsyncBlockOperation {
        
        let op = LKAsyncBlockOperation(block)
        op.prepareToExecute()
        
        return op
    }
    
    func test_execute_blockShouldBeInvokeWhenAddOperationToQueue() {
        
        //Give
        let expectation = expectation(description: "Expect to be invoked")
        let sut = makeBlockOperationSut(block: { op in
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
        
        let sut = makeBlockOperationSut(block: { op in
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
        
        let sut = makeBlockOperationSut()
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
        
        let sut = makeBlockOperationSut()
        let experimentalResult = sut.block{ _ in }
        
        let expectResult = sut
        
        //When
        
        
        //Then
        XCTAssertEqual(experimentalResult, expectResult)
    }
}
