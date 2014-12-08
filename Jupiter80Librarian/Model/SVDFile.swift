//
//  SVDFile.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

enum SVDFileFormat {
	case Unknown
	case Jupiter80
	case Jupiter50
}

private let kBytesSVD = SVDBytes(location: 0x2, bytes: [0x53, 0x56, 0x44])
private let kBytesREG = SVDBytes(location: 0x10, bytes: [0x52, 0x45, 0x47])
private let kBytesJPTR = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x54, 0x52])
private let kBytesJP50 = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x35, 0x30])
private let kBytesVCL = SVDBytes(location: 0x40, bytes: [0x56, 0x43, 0x4C])
private let kBytesSYS = SVDBytes(location: 0x50, bytes: [0x53, 0x59, 0x53])
private let kBytesRBN = SVDBytes(location: 0x60, bytes: [0x52, 0x42, 0x4E])

private let kRegLengthLocation = 0x40
private let kRegLengthLength = 4
private let kRegLength = 0x2F4
private let kRegOffset = 0x50
private let kLiveLengthLength = 4
private let kLiveLength = 0x48E
private let kLiveMetaLength = 0x0c
private let kToneLengthLength = 4
private let kToneLength = 0xA8
private let kToneMetaLength = 0x0c

class SVDFile: NSObject {
	private let svdUtils: SVDUtils
	private var isFileValid: Bool = false
	private var headerOffset: Int = 0x0
	private var regOffset: Int = 0x0
	private var liveOffset: Int = 0x0
	private var toneOffset: Int = 0x0

	var fileFormat: SVDFileFormat = .Unknown
	var nrOfRegs: Int = 0
	var nrOfLives: Int = 0
	var nrOfTones: Int = 0
	var registrations: [SVDRegistration] = []

	init(fileData: NSData) {
		self.svdUtils = SVDUtils(fileData: fileData)

		super.init()

		self.isFileValid = self.checkValidityOfData(fileData)

		if !self.isFileValid {
			return;
		}

		self.findHeaderOffset()
		self.findPartLengths()
		self.findRegistrations()
	}

	private func checkValidityOfData(fileData: NSData) -> Bool {
		// Check for string SVD
		let isSVDFile = self.svdUtils.compareData(kBytesSVD)

		if !isSVDFile {
			return false
		}

		// Check for string REG
		let isRegFile = self.svdUtils.compareData(kBytesREG)

		if isRegFile {
			// Check for string JPTR
			let isJupiter80File = self.svdUtils.compareData(kBytesJPTR)

			if isJupiter80File {
				self.fileFormat = .Jupiter80
			} else {
				// Check for string JP50
				let isJupiter50File = self.svdUtils.compareData(kBytesJP50)

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
		let hasVCLPart = self.svdUtils.compareData(kBytesVCL)

		if hasVCLPart {
			self.headerOffset += 0x10
		}

		let hasSYSPart = self.svdUtils.compareData(kBytesSYS)

		if hasSYSPart {
			self.headerOffset += 0x10
		}

		let hasRBNPart = self.svdUtils.compareData(kBytesRBN)

		if hasRBNPart {
			self.headerOffset += 0x10
		}
	}

	private func findPartLengths() {
		self.regOffset = kRegOffset + self.headerOffset
		let nrOfRegsOffset = kRegLengthLocation + self.headerOffset
		let nrOfRegsBytes = SVDBytes(location: nrOfRegsOffset, length: kRegLengthLength)
		self.nrOfRegs = self.svdUtils.numberFromBytes(nrOfRegsBytes)
		let nrOfLivesOffset = kRegOffset + (nrOfRegs * kRegLength)
		let nrOfLivesBytes = SVDBytes(location: nrOfLivesOffset, length: kLiveLengthLength)
		self.nrOfLives = self.svdUtils.numberFromBytes(nrOfLivesBytes)
		self.liveOffset = nrOfLivesOffset + kLiveLengthLength + kLiveMetaLength
		let nrOfTonesOffset = liveOffset + (nrOfLives * kLiveLength)
		let nrOfTonesBytes = SVDBytes(location: nrOfTonesOffset, length: kToneLengthLength)
		self.nrOfTones = self.svdUtils.numberFromBytes(nrOfTonesBytes)
		self.toneOffset = nrOfTonesOffset + kToneLengthLength + kToneMetaLength

		NSLog("Nr of regs: %d", nrOfRegs)
		NSLog("Nr of lives: %d", nrOfLives)
		NSLog("Nr of tones: %d", nrOfTones)
	}

	private func findRegistrations() {
		var regCount = 0

		for index in 0..<self.nrOfRegs {
			var regBytes = SVDBytes(location: self.regOffset + (kRegLength * index), length: kRegLength)

			let registration = SVDRegistration(svdUtils: self.svdUtils, regBytes: regBytes)
			self.registrations.append(registration)
		}
	}
}
