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

enum SVDPartTypeMainType {
	case Unknown
	case LiveSet
	case Synth
	case Acoustic
	case DrumSet
}

enum SVDPartTypeSubType {
	case Unknown
	case LiveSet1
	case LiveSet2
	case Synth1
	case Synth2
	case AcousticPiano
	case Acoustic1
	case Acoustic2
	case Acoustic3
	case AcousticTWOrgan
	case DrumSet1
	case DrumSet2
}

struct SVDPartType {
	let mainType: SVDPartTypeMainType
	let subType: SVDPartTypeSubType
}

private let kBytesSVD = SVDBytes(location: 0x2, bytes: [0x53, 0x56, 0x44])
private let kBytesREG = SVDBytes(location: 0x10, bytes: [0x52, 0x45, 0x47])
private let kBytesJPTR = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x54, 0x52])
private let kBytesJP50 = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x35, 0x30])
private let kBytesVCL = SVDBytes(location: 0x40, bytes: [0x56, 0x43, 0x4C])
private let kBytesSYS = SVDBytes(location: 0x50, bytes: [0x53, 0x59, 0x53])
private let kBytesRBN = SVDBytes(location: 0x60, bytes: [0x52, 0x42, 0x4E])

private let kLiveMetaLength = 0x0c
private let kToneMetaLength = 0x0c

private let kPartTypeLiveSet1 = 0xD4
private let kPartTypeLiveSet2 = 0x54
private let kPartTypeSynth1 = 0xDD
private let kPartTypeSynth2 = 0x5D
private let kPartTypeAcousticPiano = 0x5A // MSB: 90
private let kPartTypeAcoustic1 = 0x59 // MSB: 89
private let kPartTypeAcoustic2 = 0xD9
private let kPartTypeAcoustic3 = 0xDA
private let kPartTypeAcousticTWOrgan = 0x5C
private let kPartTypeDrumSet1 = 0x56
private let kPartTypeDrumSet2 = 0xD6

class SVDFile: NSObject {
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

		for svdReg in self.registrations {
			svdReg.findDependencies()
		}

		for svdLive in self.liveSets {
			svdLive.findDependencies()
		}
	}

	private func checkValidityOfData(fileData: NSData) -> Bool {
		// Check for string SVD
		let isSVDFile = self.compareData(kBytesSVD)

		if !isSVDFile {
			NSNotificationCenter.defaultCenter().postNotificationName("svdFileIsInvalid", object: nil)
			return false
		}

		// Check for string REG
		let isRegFile = self.compareData(kBytesREG)

		if isRegFile {
			// Check for string JPTR
			let isJupiter80File = self.compareData(kBytesJPTR)

			if isJupiter80File {
				self.fileFormat = .Jupiter80
			} else {
				// Check for string JP50
				let isJupiter50File = self.compareData(kBytesJP50)

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
		let hasVCLPart = self.compareData(kBytesVCL)

		if hasVCLPart {
			self.headerOffset += 0x10
		}

		let hasSYSPart = self.compareData(kBytesSYS)

		if hasSYSPart {
			self.headerOffset += 0x10
		}

		let hasRBNPart = self.compareData(kBytesRBN)

		if hasRBNPart {
			self.headerOffset += 0x10
		}
	}

	private func findPartLengths() {
		self.regBytes.location += self.headerOffset
		self.nrOfRegsBytes.location += self.headerOffset

		self.nrOfRegs = self.numberFromBytes(self.nrOfRegsBytes)

		self.nrOfLivesBytes.location = self.regBytes.location + (self.nrOfRegs * self.regBytes.length)
		self.nrOfLives = self.numberFromBytes(self.nrOfLivesBytes)
		self.liveBytes.location = self.nrOfLivesBytes.location + self.nrOfLivesBytes.length + kLiveMetaLength

		self.nrOfTonesBytes.location = self.liveBytes.location + (self.nrOfLives * self.liveBytes.length)
		self.nrOfTones = self.numberFromBytes(self.nrOfTonesBytes)
		self.toneBytes.location = self.nrOfTonesBytes.location + self.nrOfTonesBytes.length + kToneMetaLength

		NSLog("Nr of regs: %d", self.nrOfRegs)
		NSLog("Nr of lives: %d", self.nrOfLives)
		NSLog("Nr of tones: %d", self.nrOfTones)
	}

	private func findRegistrations() {
		for index in 0..<self.nrOfRegs {
			var regBytes = self.regBytes
			regBytes.location += (regBytes.length * index)

			let registration = SVDRegistration(svdFile: self, regBytes: regBytes, regBytesOffset: self.regBytes.location - self.headerOffset, orderNr: index + 1)
			self.registrations.append(registration)
		}
	}

	private func findLiveSets() {
		for index in 0..<self.nrOfLives {
			var liveBytes = self.liveBytes
			liveBytes.location += (liveBytes.length * index)

			let liveSet = SVDLiveSet(svdFile: self, liveBytes: liveBytes, orderNr: index + 1)
			self.liveSets.append(liveSet)
		}
	}

	private func findTones() {
		for index in 0..<self.nrOfTones {
			var toneBytes = self.toneBytes
			toneBytes.location += (toneBytes.length * index)

			let tone = SVDTone(svdFile: self, toneBytes: toneBytes, orderNr: index + 1)
			self.tones.append(tone)
		}
	}

	func dataFromBytes(byteStruct: SVDBytes) -> NSData {
		let byteRange = NSRange(location: byteStruct.location, length: byteStruct.length)
		let byteData = self.fileData.subdataWithRange(byteRange)

		return byteData
	}

	func compareData(byteStruct: SVDBytes) -> Bool {
		let byteData = self.dataFromBytes(byteStruct)
		let byteCheck = NSData(bytes: byteStruct.bytes, length: byteStruct.length)

		return byteData.isEqualToData(byteCheck)
	}

	func numberFromBytes(byteStruct: SVDBytes) -> Int {
		let byteData = self.dataFromBytes(byteStruct)

		let number = self.numberFromData(byteData, nrOfBits:8)

		return number
	}

	func numberFromShiftedBytes(byteStruct: SVDBytes) -> Int {
		let byteData = self.unshiftedBytesFromBytes(byteStruct)

		let number = self.numberFromData(byteData, nrOfBits:7)

		return number
	}

	func numberFromData(byteData: NSData, nrOfBits: Int) -> Int {
		var bytes: [UInt8] = Array(count: byteData.length, repeatedValue: 0x0)
		byteData.getBytes(&bytes, length: byteData.length)

		var number: Int = Int(bytes.last!)

		var iteration = 0
		var restBytes = bytes[0...bytes.count - 2]

		for byte in restBytes.reverse() {
			let convertedNumber = Int(byte) * Int(pow(Double(2), Double(nrOfBits + iteration)))
			number += convertedNumber
			iteration++
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

	func unshiftedBytesFromBytes(byteStruct: SVDBytes) -> NSData {
		var unshiftedBytes: [UInt8] = []

		let byteData = self.dataFromBytes(byteStruct)

		// Bitmasks to cycle through in order to retrieve the unshifted bytes
		let bitmasks: [UInt16] = [0b1111111000000000, 0b0000000111111100, 0b0000001111111000, 0b0000011111110000, 0b0000111111100000, 0b0001111111000000, 0b0011111110000000, 0b0111111100000000]

		// Bit shifts to cycle through to shift the extracted bits into their correct positions
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

			// Store the one unshifted byte extracted from the two shifted bytes
			let oneByteData = NSData(bytes: bitsShifted, length: 1)
			var oneByte: UInt8 = 0x0
			oneByteData.getBytes(&oneByte)
			unshiftedBytes.append(oneByte)
		}

		let unshiftedData = NSData(bytes: unshiftedBytes, length: unshiftedBytes.count)

		return unshiftedData
	}

	func unshiftedNumberFromBytes(byteStruct: SVDBytes, nrOfBits: Int) -> Int {
		let byteData = self.dataFromBytes(byteStruct)

		var oneByte: UInt8 = 0x0
		byteData.getBytes(&oneByte, range: NSRange(location: 0, length: 1))
		let bitsShifted = [oneByte >> (8 - nrOfBits)]

		return Int(bitsShifted.first!)
	}

	func stringFromShiftedBytes(byteStruct: SVDBytes) -> String {
		var data = self.unshiftedBytesFromBytes(byteStruct)

		let dataString = self.stringFromData(data)

		return dataString
	}

	func stringFromData(data: NSData) -> String {
		var dataString: String = NSString(data: data, encoding: NSASCIIStringEncoding)!

		return dataString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
	}

	func partMapKeyFromShiftedBytes(byteStruct: SVDBytes, location: Int) -> String {
		var data = self.unshiftedBytesFromBytes(byteStruct)

		let partMapKey = self.partMapKeyFromData(data, location: location)

		return partMapKey
	}

	func partMapKeyFromData(byteData: NSData, location: Int) -> String {
		var byteArray = [UInt8](count: 2, repeatedValue: 0x0)
		byteData.getBytes(&byteArray, range: NSRange(location: location, length: 2))

		let value1 = byteArray[0]
		let value2 = byteArray[1]

		let partMapKey = NSString(format: "%d %d", value1, value2 + 1) as String

		return partMapKey
	}

	func hexStringFromShiftedBytes(byteStruct: SVDBytes) -> String {
		var data = self.unshiftedBytesFromBytes(byteStruct)

		var byteArray = [UInt8](count: data.length, repeatedValue: 0x0)
		data.getBytes(&byteArray, length:data.length)

		var hexString = "" as String
		for value in byteArray {
			hexString += NSString(format: "%2X", value) as String
		}

		return hexString
	}

	func pcmMapKeyFromNibbleBytes(byteStruct: SVDBytes) -> String {
		var data = self.dataFromBytes(byteStruct)

		var byteArray = [UInt8](count: 2, repeatedValue: 0x0)
		data.getBytes(&byteArray, length:2)

		var hexString = "" as String
		for value in byteArray {
			hexString += NSString(format: "%02X", value) as String
		}

		// Remove last nibble which belongs to the next byte
		hexString = hexString.substringToIndex(hexString.endIndex.predecessor())

		return hexString
	}

	func pcmNameFromNibbleBytes(byteStruct: SVDBytes) -> String {
		let pcmKey = self.pcmMapKeyFromNibbleBytes(byteStruct)

		var pcmName = kPCMMap[pcmKey]

		if pcmName == nil {
			pcmName = ""
		}

		return pcmName!
	}

	func partTypeFromBytes(byteStruct: SVDBytes) -> SVDPartType {
		let partTypeData = self.dataFromBytes(byteStruct)

		let partType = self.partTypeFromData(partTypeData)

		return partType
	}

	func partTypeFromData(byteData: NSData) -> SVDPartType {
		var mainType = SVDPartTypeMainType.Unknown
		var subType = SVDPartTypeSubType.Unknown

		var partByte: Int = 0x0
		byteData.getBytes(&partByte, length: 1)

		if partByte == kPartTypeSynth1 {
			mainType = .Synth
			subType = .Synth1
		} else if partByte == kPartTypeSynth2 {
			mainType = .Synth
			subType = .Synth2
		} else if partByte == kPartTypeAcousticPiano {
			mainType = .Acoustic
			subType = .AcousticPiano
		} else if partByte == kPartTypeAcoustic1 {
			mainType = .Acoustic
			subType = .Acoustic1
		} else if partByte == kPartTypeAcoustic2 {
			mainType = .Acoustic
			subType = .Acoustic2
		} else if partByte == kPartTypeAcoustic3 {
			mainType = .Acoustic
			subType = .Acoustic3
		} else if partByte == kPartTypeAcousticTWOrgan {
			mainType = .Acoustic
			subType = .AcousticTWOrgan
		} else if partByte == kPartTypeDrumSet1 {
			mainType = .DrumSet
			subType = .DrumSet1
		} else if partByte == kPartTypeDrumSet2 {
			mainType = .DrumSet
			subType = .DrumSet2
		} else if partByte == kPartTypeLiveSet1 {
			mainType = .LiveSet
			subType = .LiveSet1
		} else if partByte == kPartTypeLiveSet2 {
			mainType = .LiveSet
			subType = .LiveSet2
		}

		let partType = SVDPartType(mainType: mainType, subType: subType)

		return partType
	}

	func partNameFromShiftedBytes(byteStruct: SVDBytes, partType: SVDPartType) -> String {
		let partKey = self.partMapKeyFromShiftedBytes(byteStruct, location: 0)

		var partName = self.partNameFromPartKey(partKey, partType: partType)

		return partName
	}

	func partNameFromData(byteData: NSData, partType: SVDPartType) -> String {
		let partKey = self.partMapKeyFromData(byteData, location: 0)

		var partName = self.partNameFromPartKey(partKey, partType: partType)

		return partName
	}

	func partNameFromPartKey(partKey: String, partType: SVDPartType) -> String {
		var partName: String?

		if partType.mainType == .Acoustic {
			if partType.subType == .AcousticPiano {
				partName = kPartMapAcousticPianos[partKey]
			} else {
				partName = kPartMapAcoustic[partKey]
			}
		} else if partType.mainType == .DrumSet {
			partName = kPartMapDrumSet[partKey]
		}

		if partName == nil {
			partName = ""
		}

		return partName!
	}
}
