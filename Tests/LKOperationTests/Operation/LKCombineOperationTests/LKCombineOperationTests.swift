//
//  LKCombineOperationTests.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/23.
//

import Foundation
import XCTest
import LKOperation

class LKCombineOperationTests: XCTestCase {
    
    enum TestError: Error {
        case test
    }
    
    var queue: OperationQueue!
    
    override func setUp() {
        queue = OperationQueue()
    }
    
    //其中一個 operation cancel 或自己 cancel 就判定 cancel
    func test_operationCancel_combineOperationShouldBeCancel() {
        //Give
        let aOp = LKAsyncSequenceOperation<Int>()
        aOp.block{ controller in
            controller.finished(false)
        }
        
        let bOp = LKAsyncSequenceOperation<String>()
        bOp.cancel()
        
        let expectation = expectation(description: "Block should be invoked")
        let sut = LKCombineOperation(aOp, bOp) { result in
            expectation.fulfill()
        }
        
        sut.prepareToExecute()
        
        //When
        sut.addTo(queue: queue)
        
        //Then
        wait(for: [expectation], timeout: 3)
        XCTAssertTrue(sut.isCancelled)
    }
    
    //其中一個有 error 就算 failure
    func test_operationFailure_combineOperationShouldFail() {
        //Give
        let expectResult = TestError.test
        var experimentalResult: Result<(Int, String), Error>?
        
        let aOp = LKAsyncSequenceOperation<Int>()
        aOp.block{ controller in
            controller.failure(TestError.test)
            controller.finished(false)
        }
        
        let bOp = LKAsyncSequenceOperation<String>()
        bOp.block{ controller in
            controller.success("A")
            controller.finished(false)
        }
        
        let expectation = expectation(description: "Block should be invoked")
        let sut = LKCombineOperation(aOp, bOp) { result in
            experimentalResult = result
            expectation.fulfill()
        }
        
        sut.prepareToExecute()
        
        //When
        sut.addTo(queue: queue)
        
        //Then
        wait(for: [expectation], timeout: 3)
        switch experimentalResult {
        case .failure(let error):
            XCTAssertEqual(error as? TestError, expectResult)
        default:
            XCTFail("Result should be failure case.")
        }
    }
    
    //兩個都有 success 才 success
    func test_operationBothSuccess_combineOperationShouldSuccess() {
        //Give
        let expectResult = (10, "A")
        var experimentalResult: Result<(Int, String), Error>?
        
        let aOp = LKAsyncSequenceOperation<Int>()
        aOp.block{ controller in
            controller.success(expectResult.0)
            controller.finished(false)
        }
        
        let bOp = LKAsyncSequenceOperation<String>()
        bOp.block{ controller in
            controller.success(expectResult.1)
            controller.finished(false)
        }
        
        let expectation = expectation(description: "Block should be invoked")
        let sut = LKCombineOperation(aOp, bOp) { result in
            experimentalResult = result
            expectation.fulfill()
        }
        
        sut.prepareToExecute()
        
        //When
        sut.addTo(queue: queue)
        
        //Then
        wait(for: [expectation], timeout: 3)
        switch experimentalResult {
        case .success(let result):
            XCTAssertEqual(result.0, expectResult.0)
            XCTAssertEqual(result.1, expectResult.1)
        default:
            XCTFail("Result should be failure case.")
        }
    }
}
