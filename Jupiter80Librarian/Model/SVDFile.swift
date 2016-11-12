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
	case unknown
	case jupiter80
	case jupiter50
}

enum SVDPartTypeMainType {
	case unknown
	case liveSet
	case synth
	case acoustic
	case drumSet
}

enum SVDPartTypeSubType {
	case unknown
	case liveSet1
	case liveSet2
	case synth1
	case synth2
	case acousticPiano
	case acoustic1
	case acoustic2
	case acoustic3
	case acousticTWOrgan
	case drumSet1
	case drumSet2
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
	fileprivate var nrOfRegsBytes = SVDBytes(location: 0x40, length: 0x4)
	fileprivate var regBytes = SVDBytes(location: 0x50, length: 0x2F4)
	fileprivate var nrOfLivesBytes = SVDBytes(location: 0x0, length: 0x4)
	fileprivate var liveBytes = SVDBytes(location: 0x0, length: 0x48E)
	fileprivate var nrOfTonesBytes = SVDBytes(location: 0x0, length: 0x4)
	fileprivate var toneBytes = SVDBytes(location: 0x0, length: 0xA8)

	fileprivate let fileData: Data

	fileprivate var isFileValid: Bool = false

	var headerOffset: Int = 0x0

	var fileFormat: SVDFileFormat = .unknown

	var nrOfRegs: Int = 0
	var nrOfLives: Int = 0
	var nrOfTones: Int = 0

	var registrations: [SVDRegistration] = []
	var liveSets: [SVDLiveSet] = []
	var tones: [SVDTone] = []

	init(fileData: Data) {
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

	fileprivate func checkValidityOfData(_ fileData: Data) -> Bool {
		// Check for string SVD
		let isSVDFile = self.compareData(kBytesSVD)

		if !isSVDFile {
			NotificationCenter.default.post(name: Notification.Name(rawValue: "svdFileIsInvalid"), object: nil)
			return false
		}

		// Check for string REG
		let isRegFile = self.compareData(kBytesREG)

		if isRegFile {
			// Check for string JPTR
			let isJupiter80File = self.compareData(kBytesJPTR)

			if isJupiter80File {
				self.fileFormat = .jupiter80
			} else {
				// Check for string JP50
				let isJupiter50File = self.compareData(kBytesJP50)

				if isJupiter50File {
					self.fileFormat = .jupiter50
				}
			}
		} else {
			return false
		}

		return true;
	}

	fileprivate func findHeaderOffset() {
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

	fileprivate func findPartLengths() {
		self.regBytes.location += self.headerOffset
		self.nrOfRegsBytes.location += self.headerOffset

		self.nrOfRegs = self.numberFromBytes(self.nrOfRegsBytes)

		self.nrOfLivesBytes.location = self.regBytes.location + (self.nrOfRegs * self.regBytes.length)
		self.nrOfLives = self.numberFromBytes(self.nrOfLivesBytes)
		self.liveBytes.location = self.nrOfLivesBytes.location + self.nrOfLivesBytes.length + kLiveMetaLength

		self.nrOfTonesBytes.location = self.liveBytes.location + (self.nrOfLives * self.liveBytes.length)
		self.nrOfTones = self.numberFromBytes(self.nrOfTonesBytes)
		self.toneBytes.location = self.nrOfTonesBytes.location + self.nrOfTonesBytes.length + kToneMetaLength

		DLog("Nr of regs: \(self.nrOfRegs)")
		DLog("Nr of lives: \(self.nrOfLives)")
		DLog("Nr of tones: \(self.nrOfTones)")
	}

	fileprivate func findRegistrations() {
		for index in 0..<self.nrOfRegs {
			var regBytes = self.regBytes
			regBytes.location += (regBytes.length * index)

			let registration = SVDRegistration(svdFile: self, regBytes: regBytes, regBytesOffset: self.regBytes.location - self.headerOffset, orderNr: index + 1)
			self.registrations.append(registration)
		}
	}

	fileprivate func findLiveSets() {
		for index in 0..<self.nrOfLives {
			var liveBytes = self.liveBytes
			liveBytes.location += (liveBytes.length * index)

			let liveSet = SVDLiveSet(svdFile: self, liveBytes: liveBytes, orderNr: index + 1)
			self.liveSets.append(liveSet)
		}
	}

	fileprivate func findTones() {
		for index in 0..<self.nrOfTones {
			var toneBytes = self.toneBytes
			toneBytes.location += (toneBytes.length * index)

			let tone = SVDTone(svdFile: self, toneBytes: toneBytes, orderNr: index + 1)
			self.tones.append(tone)
		}
	}

	func dataFromBytes(_ byteStruct: SVDBytes) -> Data {
		let byteRange: Range = byteStruct.location..<byteStruct.location + byteStruct.length
		let byteData = self.fileData.subdata(in: byteRange)

		return byteData
	}

	func compareData(_ byteStruct: SVDBytes) -> Bool {
		let byteData = self.dataFromBytes(byteStruct)
		let byteCheck = Data(bytes: UnsafePointer<UInt8>(byteStruct.bytes), count: byteStruct.length)

		return (byteData == byteCheck)
	}

	func numberFromBytes(_ byteStruct: SVDBytes) -> Int {
		let byteData = self.dataFromBytes(byteStruct)

		let number = self.numberFromData(byteData, nrOfBits:8)

		return number
	}

	func numberFromShiftedBytes(_ byteStruct: SVDBytes) -> Int {
		let byteData = self.unshiftedBytesFromBytes(byteStruct)

		let number = self.numberFromData(byteData, nrOfBits:7)

		return number
	}

	func numberFromData(_ byteData: Data, nrOfBits: Int) -> Int {
		var bytes: [UInt8] = Array(repeating: 0x0, count: byteData.count)
		(byteData as NSData).getBytes(&bytes, length: byteData.count)

		var number: Int = Int(bytes.last!)

		var iteration = 0
		let restBytes = bytes[0...bytes.count - 2]

		for byte in Array(restBytes.reversed()) {
			let convertedNumber = Int(byte) * Int(pow(Double(2), Double(nrOfBits + iteration)))
			number += convertedNumber
			iteration += 1
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

	func unshiftedBytesFromBytes(_ byteStruct: SVDBytes) -> Data {
		var unshiftedBytes: [UInt8] = []

		let byteData = self.dataFromBytes(byteStruct)

		// Bitmasks to cycle through in order to retrieve the unshifted bytes
		let bitmasks: [UInt16] = [0b1111111000000000, 0b0000000111111100, 0b0000001111111000, 0b0000011111110000, 0b0000111111100000, 0b0001111111000000, 0b0011111110000000, 0b0111111100000000]

		// Bit shifts to cycle through to shift the extracted bits into their correct positions
		let shiftbits: [UInt16] = [9, 2, 3, 4, 5, 6, 7, 8]

		var byteIndex = 0
		var bitmaskIndex = 0

		for _ in 0..<byteStruct.length {
			var twoBytes: UInt16 = 0x0
			(byteData as NSData).getBytes(&twoBytes, range: NSRange(location: byteIndex, length: 2))
			twoBytes = twoBytes.bigEndian
			let secondBits = twoBytes & bitmasks[bitmaskIndex]
			let bitsShifted = [secondBits >> shiftbits[bitmaskIndex]]

			bitmaskIndex += 1

			if bitmaskIndex > 7 {
				// The bitmasks repeat each eight iteration, so reset the index
				bitmaskIndex = 0
			}

			// 7 bytes shifted contain 8 bytes of information unshifted.
			// For each second byte, skip incrementing the index by 1.
			if bitmaskIndex != 1 {
				byteIndex += 1
			}

			// Store the one unshifted byte extracted from the two shifted bytes
			let oneByteData = NSData(bytes: bitsShifted, length: 1)
			var oneByte: UInt8 = 0x0
			(oneByteData as NSData).getBytes(&oneByte, length: 1)
			unshiftedBytes.append(oneByte)
		}

		let unshiftedData = Data(bytes: UnsafePointer<UInt8>(unshiftedBytes), count: unshiftedBytes.count)

		return unshiftedData
	}

	func unshiftedNumberFromBytes(_ byteStruct: SVDBytes, nrOfBits: UInt8) -> Int {
		let byteData = self.dataFromBytes(byteStruct)

		var oneByte: UInt8 = 0x0
		(byteData as NSData).getBytes(&oneByte, range: NSRange(location: 0, length: 1))
		let bitsShifted = [oneByte >> (8 - nrOfBits)]

		return Int(bitsShifted.first!)
	}

	func stringFromShiftedBytes(_ byteStruct: SVDBytes) -> String {
		let data = self.unshiftedBytesFromBytes(byteStruct)

		let dataString = self.stringFromData(data)

		return dataString
	}

	func stringFromData(_ data: Data) -> String {
		let dataString: String = NSString(data: data, encoding: String.Encoding.ascii.rawValue)! as String

		return dataString.trimmingCharacters(in: CharacterSet.whitespaces)
	}

	func partMapKeyFromShiftedBytes(_ byteStruct: SVDBytes, location: Int) -> String {
		let data = self.unshiftedBytesFromBytes(byteStruct)

		let partMapKey = self.partMapKeyFromData(data, location: location)

		return partMapKey
	}

	func partMapKeyFromData(_ byteData: Data, location: Int) -> String {
		var byteArray = [UInt8](repeating: 0x0, count: 2)
		(byteData as NSData).getBytes(&byteArray, range: NSRange(location: location, length: 2))

		let value1 = byteArray[0]
		let value2 = byteArray[1]

		let partMapKey = NSString(format: "%d %d", value1, value2 + 1) as String

		return partMapKey
	}

	func hexStringFromShiftedBytes(_ byteStruct: SVDBytes) -> String {
		let data = self.unshiftedBytesFromBytes(byteStruct)

		var byteArray = [UInt8](repeating: 0x0, count: data.count)
		(data as NSData).getBytes(&byteArray, length:data.count)

		var hexString = "" as String
		for value in byteArray {
			hexString += NSString(format: "%2X", value) as String
		}

		return hexString
	}

	func pcmMapKeyFromNibbleBytes(_ byteStruct: SVDBytes) -> String {
		let data = self.dataFromBytes(byteStruct)

		var byteArray = [UInt8](repeating: 0x0, count: 2)
		(data as NSData).getBytes(&byteArray, length:2)

		var hexString = "" as String
		for value in byteArray {
			hexString += NSString(format: "%02X", value) as String
		}

		// Remove last nibble which belongs to the next byte
		hexString = hexString.substring(to: hexString.characters.index(before: hexString.endIndex))

		return hexString
	}

	func pcmNameFromNibbleBytes(_ byteStruct: SVDBytes) -> String {
		let pcmKey = self.pcmMapKeyFromNibbleBytes(byteStruct)

		var pcmName = kPCMMap[pcmKey]

		if pcmName == nil {
			pcmName = ""
		}

		return pcmName!
	}

	func partTypeFromBytes(_ byteStruct: SVDBytes) -> SVDPartType {
		let partTypeData = self.dataFromBytes(byteStruct)

		let partType = self.partTypeFromData(partTypeData)

		return partType
	}

	func partTypeFromData(_ byteData: Data) -> SVDPartType {
		var mainType = SVDPartTypeMainType.unknown
		var subType = SVDPartTypeSubType.unknown

		var partByte: Int = 0x0
		(byteData as NSData).getBytes(&partByte, length: 1)

		if partByte == kPartTypeSynth1 {
			mainType = .synth
			subType = .synth1
		} else if partByte == kPartTypeSynth2 {
			mainType = .synth
			subType = .synth2
		} else if partByte == kPartTypeAcousticPiano {
			mainType = .acoustic
			subType = .acousticPiano
		} else if partByte == kPartTypeAcoustic1 {
			mainType = .acoustic
			subType = .acoustic1
		} else if partByte == kPartTypeAcoustic2 {
			mainType = .acoustic
			subType = .acoustic2
		} else if partByte == kPartTypeAcoustic3 {
			mainType = .acoustic
			subType = .acoustic3
		} else if partByte == kPartTypeAcousticTWOrgan {
			mainType = .acoustic
			subType = .acousticTWOrgan
		} else if partByte == kPartTypeDrumSet1 {
			mainType = .drumSet
			subType = .drumSet1
		} else if partByte == kPartTypeDrumSet2 {
			mainType = .drumSet
			subType = .drumSet2
		} else if partByte == kPartTypeLiveSet1 {
			mainType = .liveSet
			subType = .liveSet1
		} else if partByte == kPartTypeLiveSet2 {
			mainType = .liveSet
			subType = .liveSet2
		}

		let partType = SVDPartType(mainType: mainType, subType: subType)

		return partType
	}

	func partNameFromShiftedBytes(_ byteStruct: SVDBytes, partType: SVDPartType) -> String {
		let partKey = self.partMapKeyFromShiftedBytes(byteStruct, location: 0)

		let partName = self.partNameFromPartKey(partKey, partType: partType)

		return partName
	}

	func partNameFromData(_ byteData: Data, partType: SVDPartType) -> String {
		let partKey = self.partMapKeyFromData(byteData, location: 0)

		let partName = self.partNameFromPartKey(partKey, partType: partType)

		return partName
	}

	func partNameFromPartKey(_ partKey: String, partType: SVDPartType) -> String {
		var partName: String?

		if partType.mainType == .acoustic {
			if partType.subType == .acousticPiano {
				partName = kPartMapAcousticPianos[partKey]
			} else {
				partName = kPartMapAcoustic[partKey]
			}
		} else if partType.mainType == .drumSet {
			partName = kPartMapDrumSet[partKey]
		}

		if partName == nil {
			partName = ""
		}

		return partName!
	}
}
