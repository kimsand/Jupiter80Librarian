//
//  SVDRegistration.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//

import Cocoa

private let kRegNameLength = 0x10

class SVDRegistration: SVDType {
	private var regUpperBytes = SVDBytes(location: 0x85, length: 0x2)
	private var regLowerBytes = SVDBytes(location: 0x8C, length: 0x2)
	private var regSoloBytes = SVDBytes(location: 0x93, length: 0x2)
	private var regPercBytes = SVDBytes(location: 0x9A, length: 0x2)

	private var regUpperTypeBytes = SVDBytes(location: 0x84, length: 0x1)
	private var regLowerTypeBytes = SVDBytes(location: 0x8B, length: 0x1)
	private var regSoloTypeBytes = SVDBytes(location: 0x92, length: 0x1)
	private var regPercTypeBytes = SVDBytes(location: 0x99, length: 0x1)

    @objc let regName: String
	@objc var upperName: String!
	@objc var lowerName: String!
	@objc var soloName: String!
	@objc var percName: String!

    private var upperLiveSet: SVDLiveSet!
	private var lowerLiveSet: SVDLiveSet!
	private(set) var soloToneType: SVDPartType!
	private(set) var percToneType: SVDPartType!
	private(set) var soloTone: SVDTone?
	private(set) var percTone: SVDTone?

	init(svdFile: SVDFile, regBytes: SVDBytes, regBytesOffset: Int, orderNr: Int) {
        let regNameBytes = SVDBytes(location: regBytes.location, length: kRegNameLength)
        regName = svdFile.stringFromShiftedBytes(regNameBytes)

        super.init(svdFile: svdFile, orderNr: orderNr)

		regUpperBytes.location += regBytes.location - regBytesOffset
		regLowerBytes.location += regBytes.location - regBytesOffset
		regSoloBytes.location += regBytes.location - regBytesOffset
		regPercBytes.location += regBytes.location - regBytesOffset

		regUpperTypeBytes.location += regBytes.location - regBytesOffset
		regLowerTypeBytes.location += regBytes.location - regBytesOffset
		regSoloTypeBytes.location += regBytes.location - regBytesOffset
		regPercTypeBytes.location += regBytes.location - regBytesOffset
	}

	private func regPartLocationForRegPartBytes(_ regPartBytes: SVDBytes) -> Data {
		let regPartLocation = svdFile.unshiftedBytesFromBytes(regPartBytes)

		return regPartLocation
	}

	func findDependencies() {
		let upperLiveSetLocation = svdFile.numberFromShiftedBytes(regUpperBytes)
		let lowerLiveSetLocation = svdFile.numberFromShiftedBytes(regLowerBytes)

		upperLiveSet = svdFile.liveSets[upperLiveSetLocation]
		upperName = upperLiveSet.liveName

		if svdFile.fileFormat == .jupiter80 {
			lowerLiveSet = svdFile.liveSets[lowerLiveSetLocation]
			lowerName = lowerLiveSet.liveName
		}

		upperLiveSet.addDependencyToRegistration(self)

		if svdFile.fileFormat == .jupiter80 {
			lowerLiveSet.addDependencyToRegistration(self)
		}

		soloToneType = svdFile.partTypeFromBytes(regSoloTypeBytes)
		percToneType = svdFile.partTypeFromBytes(regPercTypeBytes)

		if soloToneType.mainType == .synth {
			let soloToneLocation = svdFile.numberFromShiftedBytes(regSoloBytes)

			soloTone = svdFile.tones[soloToneLocation]
			soloTone?.addDependencyToRegistration(self)
			soloName = soloTone!.toneName
		} else {
			soloName = svdFile.partNameFromShiftedBytes(regSoloBytes, partType: soloToneType)
		}

		if percToneType.mainType == .synth {
			let percToneLocation = svdFile.numberFromShiftedBytes(regPercBytes)

			percTone = svdFile.tones[percToneLocation]
			percTone?.addDependencyToRegistration(self)
			percName = percTone!.toneName
		} else {
			percName = svdFile.partNameFromShiftedBytes(regPercBytes, partType: percToneType)
		}
	}
}
