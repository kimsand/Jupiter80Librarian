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

	func numberFromBytes(byteStruct: SVDBytes) -> Int {
		let byteData = self.dataFromByteStruct(byteStruct)

		var bytes: [UInt8] = Array(count: byteData.length, repeatedValue: 0x0)
		byteData.getBytes(&bytes, length: byteData.length)

		var number: Int = Int(bytes.last!)

		var iteration = 0
		var restBytes = bytes[0...bytes.count - 2]

		for byte in restBytes.reverse() {
			number += Int(byte) * (2^(8+iteration))
		}

		return number
	}

	// 7 bytes shifted contain 8 bytes of information unshifted.
	// We only need to read 7 bytes (shifted) to produce 8 (unshifted).
	// Instead of unshifting the bytes, the 7 bits can be extracted by offset.
	// We need to read at most two bytes each step to extract all 7 bits.
	// Each step we increase the byte offset by 1 (reading two bytes).
	// Each step we decrease the bit offset by 1.
	// In eight steps the bit offset has wrapped around.

	// These are the steps needed to extract 8 bytes of information:
	// 11111110 00000000 00000000 00000000 00000000 00000000 00000000 00000000
	// 00000001 11111100 00000000 00000000 00000000 00000000 00000000 00000000
	// 00000000 00000011 11111000 00000000 00000000 00000000 00000000 00000000
	// 00000000 00000000 00000111 11110000 00000000 00000000 00000000 00000000
	// 00000000 00000000 00000000 00001111 11100000 00000000 00000000 00000000
	// 00000000 00000000 00000000 00000000 00011111 11000000 00000000 00000000
	// 00000000 00000000 00000000 00000000 00000000 00111111 10000000 00000000
	// 00000000 00000000 00000000 00000000 00000000 00000000 01111111 00000000

	func stringFromBytes(byteStruct: SVDBytes) -> String {
		let byteData = self.dataFromByteStruct(byteStruct)

		let bitmasks: [UInt16] = [0b1111111000000000, 0b0000000111111100, 0b0000001111111000, 0b0000011111110000, 0b0000111111100000, 0b0001111111000000, 0b0011111110000000, 0b0111111100000000]

		let shiftbits: [UInt16] = [9, 2, 3, 4, 5, 6, 7, 8]

		var byteIndex = 0
		var bitmaskIndex = 0

		for index in 0..<byteStruct.length {
			//var twoBytes = UnsafePointer<UInt16>(byteData.bytes)[byteIndex]
			var twoBytes: UInt16 = 0x0
			byteData.getBytes(&twoBytes, range: NSRange(location: byteIndex, length: 2))
			twoBytes = twoBytes.bigEndian
			let secondBits = twoBytes & bitmasks[bitmaskIndex]
			let bitsShifted = [secondBits >> shiftbits[bitmaskIndex]]

			bitmaskIndex++

			if bitmaskIndex > 7 {
				// The bitmasks repeat each eight iteration, so reset the index
				bitmaskIndex = 0
			}

			// 7 bytes shifted contain 8 bytes of information unshifted.
			// For each second byte, skip incrementing the index by 1.
			if bitmaskIndex != 1 {
				byteIndex++
			}

			let data = NSData(bytes: bitsShifted, length: 1)
			let str = NSString(data: data, encoding: NSASCIIStringEncoding)

			NSLog(str!)
		}

		return "";
	}
}
