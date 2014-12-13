//
//  SVDRegistration.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

private let regPartTypeLiveset1 = 0xD4
private let regPartTypeLiveset2 = 0x54
private let regPartTypeSynth1 = 0xDD
private let regPartTypeSynth2 = 0x5D
private let regPartTypeAcoustic1 = 0xD9
private let regPartTypeAcoustic2 = 0x59
private let regPartTypeAcoustic3 = 0xDA
private let regPartTypeAcoustic4 = 0x5A
private let regPartTypeAcoustic5 = 0x5C
private let regPartTypeDrumset1 = 0x56
private let regPartTypeDrumset2 = 0xD6
private let kRegNameLength = 0x10

class SVDRegistration: NSObject {
	private let svdFile: SVDFile

	private var regUpperBytes = SVDBytes(location: 0x85, length: 0x2)
	private var regLowerBytes = SVDBytes(location: 0x8C, length: 0x2)
	private var regSoloBytes = SVDBytes(location: 0x93, length: 0x2)
	private var regPercBytes = SVDBytes(location: 0x9A, length: 0x2)

	private var regUpperTypeBytes = SVDBytes(location: 0x84, length: 0x1)
	private var regLowerTypeBytes = SVDBytes(location: 0x8B, length: 0x1)
	private var regSoloTypeBytes = SVDBytes(location: 0x92, length: 0x1)
	private var regPercTypeBytes = SVDBytes(location: 0x99, length: 0x1)

	var regName: String
	var upperLiveSet: SVDLiveSet!
	var lowerLiveSet: SVDLiveSet!

	init(svdFile: SVDFile, regBytes: SVDBytes, regBytesOffset: Int) {
		self.svdFile = svdFile

		let regNameBytes = SVDBytes(location: regBytes.location, length: kRegNameLength)
		self.regName = self.svdFile.stringFromBytes(regNameBytes)

		self.regUpperBytes.location += regBytes.location - regBytesOffset
		self.regLowerBytes.location += regBytes.location - regBytesOffset
		self.regSoloBytes.location += regBytes.location - regBytesOffset
		self.regPercBytes.location += regBytes.location - regBytesOffset

		self.regUpperTypeBytes.location += regBytes.location - regBytesOffset
		self.regLowerTypeBytes.location += regBytes.location - regBytesOffset
		self.regSoloTypeBytes.location += regBytes.location - regBytesOffset
		self.regPercTypeBytes.location += regBytes.location - regBytesOffset
	}

	private func regPartLocationForRegPartBytes(regPartBytes: SVDBytes) -> NSData {
		let regPartLocation = self.svdFile.unshiftedBytesFromBytes(regPartBytes)

		return regPartLocation
	}

	func findDependencies() {
		let upperLiveSetLocation = self.svdFile.numberFromShiftedBytes(self.regUpperBytes)
		let lowerLiveSetLocation = self.svdFile.numberFromShiftedBytes(self.regLowerBytes)
		let soloToneLocation = self.svdFile.numberFromShiftedBytes(self.regSoloBytes)
		let percToneLocation = self.svdFile.numberFromShiftedBytes(self.regPercBytes)

		self.upperLiveSet = svdFile.liveSets[upperLiveSetLocation]
		self.lowerLiveSet = svdFile.liveSets[lowerLiveSetLocation]

		self.upperLiveSet.addDependencyToRegistration(self)
		self.lowerLiveSet.addDependencyToRegistration(self)
	}
}
