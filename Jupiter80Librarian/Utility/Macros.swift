//
//  Macros.swift
//  Meny
//
//  Created by Kim André Sand on 19/02/15.
//  Copyright (c) 2015 Making Waves. All rights reserved.
//

import Foundation



#if DEBUG
	func DLog(message: String, filename: String = #file, function: String = #function, line: Int = #line) {
		NSLog("[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(message)")
	}
#else
	func DLog(message: String, filename: String = #file, function: String = #function, line: Int = #line) {
	}
#endif

func ALog(message: String, filename: String = #file, function: String = #function, line: Int = #line) {
	NSLog("[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(message)")
}