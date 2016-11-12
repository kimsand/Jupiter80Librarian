//
//  Macros.swift
//  Meny
//
//  Created by Kim André Sand on 19/02/15.
//  Copyright (c) 2015 Making Waves. All rights reserved.
//

import Foundation

func DLog(_ message: @autoclosure () -> String, filename: String = #file, function: String = #function, line: Int = #line) {
	#if DEBUG
		NSLog("[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(message())")
	#endif
}
