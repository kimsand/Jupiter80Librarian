//
//  SVDRegistration.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

private let kRegNameLength = 0x10

class SVDRegistration: SVDType {
	fileprivate var regUpperBytes = SVDBytes(location: 0x85, length: 0x2)
	fileprivate var regLowerBytes = SVDBytes(location: 0x8C, length: 0x2)
	fileprivate var regSoloBytes = SVDBytes(location: 0x93, length: 0x2)
	fileprivate var regPercBytes = SVDBytes(location: 0x9A, length: 0x2)

	fileprivate var regUpperTypeBytes = SVDBytes(location: 0x84, length: 0x1)
	fileprivate var regLowerTypeBytes = SVDBytes(location: 0x8B, length: 0x1)
	fileprivate var regSoloTypeBytes = SVDBytes(location: 0x92, length: 0x1)
	fileprivate var regPercTypeBytes = SVDBytes(location: 0x99, length: 0x1)

	var regName: String!
	var upperName: String!
	var lowerName: String!
	var soloName: String!
	var percName: String!
	var upperLiveSet: SVDLiveSet!
	var lowerLiveSet: SVDLiveSet!
	var soloToneType: SVDPartType!
	var percToneType: SVDPartType!
	var soloTone: SVDTone?
	var percTone: SVDTone?

	init(svdFile: SVDFile, regBytes: SVDBytes, regBytesOffset: Int, orderNr: Int) {
		super.init(svdFile: svdFile, orderNr: orderNr)

		let regNameBytes = SVDBytes(location: regBytes.location, length: kRegNameLength)
		self.regName = self.svdFile.stringFromShiftedBytes(regNameBytes)

		self.regUpperBytes.location += regBytes.location - regBytesOffset
		self.regLowerBytes.location += regBytes.location - regBytesOffset
		self.regSoloBytes.location += regBytes.location - regBytesOffset
		self.regPercBytes.location += regBytes.location - regBytesOffset

		self.regUpperTypeBytes.location += regBytes.location - regBytesOffset
		self.regLowerTypeBytes.location += regBytes.location - regBytesOffset
		self.regSoloTypeBytes.location += regBytes.location - regBytesOffset
		self.regPercTypeBytes.location += regBytes.location - regBytesOffset
	}

	fileprivate func regPartLocationForRegPartBytes(_ regPartBytes: SVDBytes) -> Data {
		let regPartLocation = self.svdFile.unshiftedBytesFromBytes(regPartBytes)

		return regPartLocation
	}

	func findDependencies() {
		let upperLiveSetLocation = self.svdFile.numberFromShiftedBytes(self.regUpperBytes)
		let lowerLiveSetLocation = self.svdFile.numberFromShiftedBytes(self.regLowerBytes)

		self.upperLiveSet = svdFile.liveSets[upperLiveSetLocation]
		self.upperName = self.upperLiveSet.liveName

		if self.svdFile.fileFormat == .jupiter80 {
			self.lowerLiveSet = svdFile.liveSets[lowerLiveSetLocation]
			self.lowerName = self.lowerLiveSet.liveName
		}

		self.upperLiveSet.addDependencyToRegistration(self)

		if self.svdFile.fileFormat == .jupiter80 {
			self.lowerLiveSet.addDependencyToRegistration(self)
		}

		self.soloToneType = self.svdFile.partTypeFromBytes(self.regSoloTypeBytes)
		self.percToneType = self.svdFile.partTypeFromBytes(self.regPercTypeBytes)

		if self.soloToneType!.mainType == .synth {
			let soloToneLocation = self.svdFile.numberFromShiftedBytes(self.regSoloBytes)

			self.soloTone = svdFile.tones[soloToneLocation]
			self.soloTone?.addDependencyToRegistration(self)
			self.soloName = self.soloTone!.toneName
		} else {
			self.soloName = svdFile.partNameFromShiftedBytes(self.regSoloBytes, partType: self.soloToneType)
		}

		if self.percToneType!.mainType == .synth {
			let percToneLocation = self.svdFile.numberFromShiftedBytes(self.regPercBytes)

			self.percTone = svdFile.tones[percToneLocation]
			self.percTone?.addDependencyToRegistration(self)
			self.percName = self.percTone!.toneName
		} else {
			self.percName = svdFile.partNameFromShiftedBytes(self.regPercBytes, partType: self.percToneType)
		}
	}
}
