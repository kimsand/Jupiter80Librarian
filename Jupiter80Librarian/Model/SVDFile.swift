//
//  SVDFile.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

let kPartMapAcousticPianos = [
	"67 1": "Concert Grand",
	"67 2": "Grand Piano1",
	"67 3": "Grand Piano2",
	"67 4": "Grand Piano3",
	"67 5": "Mellow Piano",
	"67 6": "Bright Piano",
	"67 7": "Upright Piano",
	"67 8": "Concert Mono",
	"67 9": "Honky-tonk"
]

let kPartMapAcoustic = [
	"64 5": "Pure Vintage EP1",
	"65 5": "Pure Vintage EP2",
	"66 5": "Pure Wurly",
	"67 5": "Pure Vintage EP3",
	"68 5": "Tined EP1",
	"69 5": "Tined EP2",
	"70 5": "Old Hammer EP",
	"71 5": "Dyno Piano",
	"64 8": "Clav CB Flat",
	"65 8": "Clav CA Flat",
	"66 8": "Clav CB Medium",
	"67 8": "Clav CA Medium",
	"68 8": "Clav CB Brillia",
	"69 8": "Clav CA Brillia",
	"70 8": "Clav CB Combo",
	"71 8": "Clav CA Combo",
	"64 12": "Vibraphone",
	"64 13": "Marimba",
	"64 22": "French Accordion",
	"65 22": "ItalianAccordion",
	"64 23": "Harmonica",
	"64 24": "Bandoneon",
	"64 25": "Nylon Guitar",
	"65 25": "Flamenco Guitar",
	"64 26": "SteelStr Guitar",
	"64 33": "Acoustic Bass",
	"64 34": "Fingered Bass",
	"65 34": "Fingered Bass 2",
	"64 35": "Picked Bass",
	"65 35": "Picked Bass 2",
	"64 36": "Fretless Bass",
	"64 41": "Violin",
	"65 41": "Violin 2",
	"64 42": "Viola",
	"64 43": "Cello",
	"65 43": "Cello 2",
	"64 44": "Contrabass",
	"64 47": "Harp",
	"64 48": "Timpani",
	"64 49": "Strings",
	"64 57": "Trumpet",
	"66 57": "Flugel Horn",
	"64 58": "Trombone",
	"65 58": "Trombone 2",
	"66 58": "Bass Trombone",
	"64 60": "Mute Trumpet",
	"64 61": "French Horn",
	"64 65": "Soprano Sax",
	"64 66": "Alto Sax",
	"64 67": "Tenor Sax",
	"64 68": "Baritone Sax",
	"64 69": "Oboe",
	"64 70": "English Horn",
	"64 71": "Bassoon",
	"64 72": "Clarinet",
	"65 72": "Bass Clarinet",
	"64 73": "Piccolo",
	"64 74": "Flute",
	"65 74": "Flute 2",
	"64 76": "Pan Flute",
	"64 78": "Shakuhachi",
	"65 78": "Ryuteki",
	"64 105": "Sitar",
	"64 110": "Uilleann Pipes",
	"65 111": "Erhu",
	"66 111": "Sarangi",
	"64 115": "Steel Drums",
	"80 12": "APS Vibraphone",
	"80 13": "APS Marimba",
	"80 22": "APS Accordion",
	"80 23": "APS Harmonica",
	"80 24": "APS Bandoneon",
	"80 25": "APS Nylon Guitar",
	"80 26": "APS SteelStr Gt.",
	"80 33": "APS Acoustic Bs.",
	"80 34": "APS Fingered Bs.",
	"80 35": "APS Picked Bass",
	"80 36": "APS Fretless Bs.",
	"80 41": "APS Violin",
	"80 42": "APS Viola",
	"80 43": "APS Cello",
	"80 44": "APS Contrabass",
	"80 47": "APS Harp",
	"80 48": "APS Timpani",
	"80 49": "APS Strings",
	"80 57": "APS Trumpet",
	"80 58": "APS Trombone",
	"80 60": "APS Mute Trumpet",
	"80 61": "APS French Horn",
	"80 65": "APS Soprano Sax",
	"80 66": "APS Alto Sax",
	"80 67": "APS Tenor Sax",
	"80 68": "APS Baritone Sax",
	"80 69": "APS Oboe",
	"80 70": "APS English Horn",
	"80 71": "APS Bassoon",
	"80 72": "APS Clarinet",
	"80 73": "APS Piccolo",
	"80 74": "APS Flute",
	"80 76": "APS Pan Flute",
	"80 78": "APS Shakuhachi",
	"81 78": "APS Ryuteki",
	"80 105": "APS Sitar",
	"80 110": "APS UilleannPipe",
	"81 111": "APS Erhu",
	"82 111": "APS Sarangi",
	"80 115": "APS Steel Drums",
	"0 1": "TW Organ"
]

let kPartMapDrumSet = [
	"64 1": "Standard 1",
	"64 2": "Standard 2",
	"64 3": "Standard 3",
	"64 4": "Power Kit",
	"64 5": "Jazz Kit",
	"64 6": "Brush Kit",
	"64 7": "Orchestra",
	"64 8": "SFX",
	"64 9": "Machine Kit",
	"64 10": "R&B T-Analog",
	"64 11": "R&B Mini Kit",
	"64 12": "HipHop Kit",
	"64 13": "R&B Kit",
	"64 14": "Dance Kit 1",
	"64 15": "Dance Kit 2",
	"64 16": "Dance Kit 3",
	"64 17": "Dance Kit 4",
	"65 1": "Drum Set",
	"65 2": "Latin Set",
	"65 3": "Clap&TR-808",
	"65 4": "Hit&Scratch",
	"65 5": "Zap&DigiVox",
	"65 6": "Jazz Scat",
	"65 7": "Orchestra 1",
	"65 8": "Orchestra 2"
]

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

enum SVDPartType {
	case Unknown
	case LiveSet
	case Synth
	case Acoustic
	case DrumSet
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

private let kPartTypeLiveset1 = 0xD4
private let kPartTypeLiveset2 = 0x54
private let kPartTypeSynth1 = 0xDD
private let kPartTypeSynth2 = 0x5D
private let kPartTypeAcousticPiano = 0x5A // MSB: 90
private let kPartTypeAcoustic1 = 0x59 // MSB: 89
private let kPartTypeAcoustic2 = 0xD9
private let kPartTypeAcoustic3 = 0xDA
private let kPartTypeAcoustic4 = 0x5C
private let kPartTypeDrumset1 = 0x56
private let kPartTypeDrumset2 = 0xD6

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

			let registration = SVDRegistration(svdFile: self, regBytes: regBytes, regBytesOffset: self.regBytes.location - self.headerOffset)
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

	func partTypeAndByteFromBytes(byteStruct: SVDBytes) -> (partType: SVDPartType, partByte: Int) {
		let partTypeData = self.dataFromBytes(byteStruct)

		let partTypeAndByte = self.partTypeAndByteFromData(partTypeData)

		return partTypeAndByte
	}

	func partTypeAndByteFromData(byteData: NSData) -> (partType: SVDPartType, partByte: Int) {
		var partType = SVDPartType.Unknown

		var partByte: Int = 0x0
		byteData.getBytes(&partByte, length: 1)

		if partByte == kPartTypeSynth1
			|| partByte == kPartTypeSynth2 {
				partType = .Synth
		} else if partByte == kPartTypeAcousticPiano
			|| partByte == kPartTypeAcoustic1
			|| partByte == kPartTypeAcoustic2
			|| partByte == kPartTypeAcoustic3
			|| partByte == kPartTypeAcoustic4 {
				partType = .Acoustic
		} else if partByte == kPartTypeDrumset1
			|| partByte == kPartTypeDrumset2 {
				partType = .DrumSet
		} else if partByte == kPartTypeLiveset1
			|| partByte == kPartTypeLiveset2 {
				partType = .LiveSet
		}

		return (partType, partByte)
	}

	func partNameFromShiftedBytes(byteStruct: SVDBytes, partType: SVDPartType, partByte: Int) -> String {
		let partKey = self.partMapKeyFromShiftedBytes(byteStruct, location: 0)

		var partName = self.partNameFromPartKey(partKey, partType: partType, partByte: partByte)

		return partName
	}

	func partNameFromData(byteData: NSData, partType: SVDPartType, partByte: Int) -> String {
		let partKey = self.partMapKeyFromData(byteData, location: 0)

		var partName = self.partNameFromPartKey(partKey, partType: partType, partByte: partByte)

		return partName
	}

	func partNameFromPartKey(partKey: String, partType: SVDPartType, partByte: Int) -> String {
		var partName: String?

		if partType == .Acoustic {
			if partByte == kPartTypeAcousticPiano {
				partName = kPartMapAcousticPianos[partKey]
			} else {
				partName = kPartMapAcoustic[partKey]
			}
		} else if partType == .DrumSet {
			partName = kPartMapDrumSet[partKey]
		}

		if partName == nil {
			partName = ""
		}

		return partName!
	}
}
