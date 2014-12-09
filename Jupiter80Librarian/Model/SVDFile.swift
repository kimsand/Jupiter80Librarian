//
//  SVDFile.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

struct SVDBytes {
	var location: Int
	var bytes: [UInt8]
	var length: Int

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

enum SVDFileFormat {
	case Unknown
	case Jupiter80
	case Jupiter50
}

class SVDFile: NSObject {
	private let bytesSVD = SVDBytes(location: 0x2, bytes: [0x53, 0x56, 0x44])
	private let bytesREG = SVDBytes(location: 0x10, bytes: [0x52, 0x45, 0x47])
	private let bytesJPTR = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x54, 0x52])
	private let bytesJP50 = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x35, 0x30])
	private let bytesVCL = SVDBytes(location: 0x40, bytes: [0x56, 0x43, 0x4C])
	private let bytesSYS = SVDBytes(location: 0x50, bytes: [0x53, 0x59, 0x53])
	private let bytesRBN = SVDBytes(location: 0x60, bytes: [0x52, 0x42, 0x4E])

	private let liveMetaLength = 0x0c
	private let toneMetaLength = 0x0c

	private var nrOfRegsBytes = SVDBytes(location: 0x40, length: 0x4)
	private var regBytes = SVDBytes(location: 0x50, length: 0x2F4)
	private var nrOfLivesBytes = SVDBytes(location: 0x0, length: 0x4)
	private var liveBytes = SVDBytes(location: 0x0, length: 0x48E)
	private var nrOfTonesBytes = SVDBytes(location: 0x0, length: 0x4)
	private var toneBytes = SVDBytes(location: 0x0, length: 0xA8)

	private let fileData: NSData

	private var isFileValid: Bool = false

	var headerOffset: Int = 0x0

	var fileFormat: SVDFileFormat = .Unknown

	var nrOfRegs: Int = 0
	var nrOfLives: Int = 0
	var nrOfTones: Int = 0

	var registrations: [SVDRegistration] = []
	var liveSets: [SVDLiveSet] = []
	var tones: [SVDTone] = []

	init(fileData: NSData) {
		self.fileData = fileData

		super.init()

		self.isFileValid = self.checkValidityOfData(fileData)

		if !self.isFileValid {
			return;
		}

		self.findHeaderOffset()
		self.findPartLengths()
		self.findRegistrations()
		self.findLiveSets()
		self.findTones()
	}

	private func checkValidityOfData(fileData: NSData) -> Bool {
		// Check for string SVD
		let isSVDFile = self.compareData(bytesSVD)

		if !isSVDFile {
			return false
		}

		// Check for string REG
		let isRegFile = self.compareData(bytesREG)

		if isRegFile {
			// Check for string JPTR
			let isJupiter80File = self.compareData(bytesJPTR)

			if isJupiter80File {
				self.fileFormat = .Jupiter80
			} else {
				// Check for string JP50
				let isJupiter50File = self.compareData(bytesJP50)

				if isJupiter50File {
					self.fileFormat = .Jupiter50
				}
			}
		} else {
			return false
		}

		return true;
	}

	private func findHeaderOffset() {
		let hasVCLPart = self.compareData(bytesVCL)

		if hasVCLPart {
			self.headerOffset += 0x10
		}

		let hasSYSPart = self.compareData(bytesSYS)

		if hasSYSPart {
			self.headerOffset += 0x10
		}

		let hasRBNPart = self.compareData(bytesRBN)

		if hasRBNPart {
			self.headerOffset += 0x10
		}
	}

	private func findPartLengths() {
		self.regBytes.location += self.headerOffset
		self.nrOfRegsBytes.location += self.headerOffset

		self.nrOfRegs = self.numberFromBytes(self.nrOfRegsBytes)

		self.nrOfLivesBytes.location = self.regBytes.location + (self.nrOfRegs * self.regBytes.length)
		self.nrOfLives = self.numberFromBytes(nrOfLivesBytes)
		self.liveBytes.location = self.nrOfLivesBytes.location + self.nrOfLivesBytes.length + liveMetaLength

		self.nrOfTonesBytes.location = self.liveBytes.location + (self.nrOfLives * self.liveBytes.length)
		self.nrOfTones = self.numberFromBytes(nrOfTonesBytes)
		self.toneBytes.location = self.nrOfTonesBytes.location + self.nrOfTonesBytes.length + toneMetaLength

		NSLog("Nr of regs: %d", self.nrOfRegs)
		NSLog("Nr of lives: %d", self.nrOfLives)
		NSLog("Nr of tones: %d", self.nrOfTones)
	}

	private func findRegistrations() {
		for index in 0..<self.nrOfRegs {
			var regBytes = self.regBytes
			regBytes.location += (regBytes.length * index)

			let registration = SVDRegistration(svdFile: self, regBytes: regBytes)
			self.registrations.append(registration)
		}
	}

	private func findLiveSets() {
		for index in 0..<self.nrOfLives {
			var liveBytes = self.liveBytes
			liveBytes.location += (liveBytes.length * index)

			let liveSet = SVDLiveSet(svdFile: self, liveBytes: liveBytes)
			self.liveSets.append(liveSet)
		}
	}

	private func findTones() {
		for index in 0..<self.nrOfTones {
			var toneBytes = self.toneBytes
			toneBytes.location += (toneBytes.length * index)

			let tone = SVDTone(svdFile: self, toneBytes: toneBytes)
			self.tones.append(tone)
		}
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

	func unshiftedBytesFromBytes(byteStruct: SVDBytes) -> [NSData] {
		var dataStream: [NSData] = []

		let byteData = self.dataFromByteStruct(byteStruct)

		let bitmasks: [UInt16] = [0b1111111000000000, 0b0000000111111100, 0b0000001111111000, 0b0000011111110000, 0b0000111111100000, 0b0001111111000000, 0b0011111110000000, 0b0111111100000000]

		let shiftbits: [UInt16] = [9, 2, 3, 4, 5, 6, 7, 8]

		var byteIndex = 0
		var bitmaskIndex = 0

		for index in 0..<byteStruct.length {
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
			dataStream.append(data)
		}

		return dataStream
	}

	func stringFromBytes(byteStruct: SVDBytes) -> String {
		var dataStream = self.unshiftedBytesFromBytes(byteStruct)
		var dataString: String = ""

		for data in dataStream {
			let str = NSString(data: data, encoding: NSASCIIStringEncoding)!
			dataString += str
		}

		return dataString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
	}
}
