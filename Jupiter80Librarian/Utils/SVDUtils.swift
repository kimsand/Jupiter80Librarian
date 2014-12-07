//
//  SVDUtils.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

struct SVDBytes {
	let location: Int
	let bytes: [UInt8]
	let length: Int

	init(location: Int, bytes: [UInt8]) {
		self.location = location
		self.bytes = bytes
		self.length = self.bytes.count
	}

	init(location: Int, length: Int) {
		self.location = location
		self.length = length
		self.bytes = []
	}
}

class SVDUtils: NSObject {
	private let fileData: NSData

	init(fileData: NSData) {
		self.fileData = fileData
	}

	func dataFromByteStruct(byteStruct: SVDBytes) -> NSData {
		let byteRange = NSRange(location: byteStruct.location, length: byteStruct.length)
		let byteData = self.fileData.subdataWithRange(byteRange)

		return byteData
	}

	func compareData(byteStruct: SVDBytes) -> Bool {
		let byteData = self.dataFromByteStruct(byteStruct)
		let byteCheck = NSData(bytes: byteStruct.bytes, length: byteStruct.length)

		return byteData.isEqualToData(byteCheck)
	}

	func numberFromBytes(byteStruct: SVDBytes) -> UInt {
		let byteData = self.dataFromByteStruct(byteStruct)

		var bytes: [UInt8] = Array(count: byteData.length, repeatedValue: 0x0)
		byteData.getBytes(&bytes, length: byteData.length)

		var number: UInt = UInt(bytes.last!)

		var iteration = 0
		var restBytes = bytes[0...bytes.count - 2]

		for byte in restBytes.reverse() {
			number += UInt(byte) * (2^(8+iteration))
		}

		return number
	}
}
