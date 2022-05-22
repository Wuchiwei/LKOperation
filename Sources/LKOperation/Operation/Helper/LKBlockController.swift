//
//  LKBlockController.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/13.
//

import Foundation

/// Collecting relative action with operation for manipulating esaily.

public struct LKBlockController<T> {
    
    public let success: (T) -> Void
    
    public let failure: (Error) -> Void
    
    public let finished: (Bool) -> Void
    
    public let isCancelled: () -> Bool
}
