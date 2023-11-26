//
//  Macros.swift
//  Meny
//
//  Created by Kim André Sand on 19/02/15.
//

import Foundation

func DLog(_ message: @autoclosure () -> String, filename: String = #file, function: String = #function, line: Int = #line) {
	#if DEBUG
		NSLog("[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(message())")
	#endif
}
