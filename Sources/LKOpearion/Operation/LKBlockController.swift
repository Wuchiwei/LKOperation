//
//  LKBlockController.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/13.
//

import Foundation

public struct LKBlockController {
    
    public let success: () -> Void
    
    public let failure: (Error) -> Void
    
    public let complete: () -> Void
    
    public let isCancelled: () -> Bool
}
