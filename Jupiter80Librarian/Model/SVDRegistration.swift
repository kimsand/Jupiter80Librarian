//
//  SVDRegistration.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

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
	var soloToneType: SVDPartType!
	var percToneType: SVDPartType!
	var soloTone: SVDTone?
	var percTone: SVDTone?

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

		let soloToneType = self.svdFile.partTypeFromBytes(self.regSoloTypeBytes)
		let percToneType = self.svdFile.partTypeFromBytes(self.regPercTypeBytes)

		if soloToneType == .Synth {
			self.soloTone = svdFile.tones[soloToneLocation]
			self.soloTone?.addDependencyToRegistration(self)
		}

		if percToneType == .Synth {
			self.percTone = svdFile.tones[percToneLocation]
			self.percTone?.addDependencyToRegistration(self)
		}
	}
}
