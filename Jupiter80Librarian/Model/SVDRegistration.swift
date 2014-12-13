//
//  SVDRegistration.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class SVDRegistration: NSObject {
	private let svdFile: SVDFile

	private let regNameLength = 0x10
	private var regUpperBytes = SVDBytes(location: 0x85, length: 0x2)
	private var regLowerBytes = SVDBytes(location: 0x8C, length: 0x2)
	private var regSoloBytes = SVDBytes(location: 0x93, length: 0x2)
	private var regPercBytes = SVDBytes(location: 0x9A, length: 0x2)

	private var regUpperTypeBytes = SVDBytes(location: 0x84, length: 0x1)
	private var regLowerTypeBytes = SVDBytes(location: 0x8B, length: 0x1)
	private var regSoloTypeBytes = SVDBytes(location: 0x92, length: 0x1)
	private var regPercTypeBytes = SVDBytes(location: 0x99, length: 0x1)

	private var regPartTypeLiveset1 = 0xD4
	private var regPartTypeLiveset2 = 0x54
	private var regPartTypeSynth1 = 0xDD
	private var regPartTypeSynth2 = 0x5D
	private var regPartTypeAcoustic1 = 0xD9
	private var regPartTypeAcoustic2 = 0x59
	private var regPartTypeAcoustic3 = 0xDA
	private var regPartTypeAcoustic4 = 0x5A
	private var regPartTypeAcoustic5 = 0x5C
	private var regPartTypeDrumset1 = 0x56
	private var regPartTypeDrumset2 = 0xD6

	var regName: String

	init(svdFile: SVDFile, regBytes: SVDBytes, regBytesOffset: Int) {
		self.svdFile = svdFile

		let regNameBytes = SVDBytes(location: regBytes.location, length: self.regNameLength)
		self.regName = self.svdFile.stringFromBytes(regNameBytes)

		self.regUpperBytes.location += regBytes.location - regBytesOffset
		self.regLowerBytes.location += regBytes.location - regBytesOffset
		self.regSoloBytes.location += regBytes.location - regBytesOffset
		self.regPercBytes.location += regBytes.location - regBytesOffset

		self.regUpperTypeBytes.location += regBytes.location - regBytesOffset
		self.regLowerTypeBytes.location += regBytes.location - regBytesOffset
		self.regSoloTypeBytes.location += regBytes.location - regBytesOffset
		self.regPercTypeBytes.location += regBytes.location - regBytesOffset

		super.init()

		let upperLiveSetLocation = self.regPartLocationForRegPartBytes(self.regUpperBytes)
		let lowerLiveSetLocation = self.regPartLocationForRegPartBytes(self.regLowerBytes)
		let soloToneLocation = self.regPartLocationForRegPartBytes(self.regSoloBytes)
		let percToneLocation = self.regPartLocationForRegPartBytes(self.regPercBytes)
	}

	func regPartLocationForRegPartBytes(regPartBytes: SVDBytes) -> NSData {
		let regPartLocation = self.svdFile.unshiftedBytesFromBytes(regPartBytes)

		return regPartLocation
	}
/*
	func regPartNameForRegPartTypeBytes(regPartTypeBytes: SVDBytes) -> String {
		let regPartType = self.svdFile.dataFromByteStruct(regPartTypeBytes)
		let regPartName
	}
*/
	func regPartNameForRegPartType(regPartType: NSData) {

	}
}
