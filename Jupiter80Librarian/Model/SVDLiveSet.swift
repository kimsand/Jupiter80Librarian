//
//  SVDLiveSet.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 09/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

private let kLiveNameLength = 0x10

class SVDLiveSet: NSObject {
	private let svdFile: SVDFile

	private var liveLayer1Bytes = SVDBytes(location: 0x19F, length: 0x3)
	private var liveLayer2Bytes = SVDBytes(location: 0x1C5, length: 0x3)
	private var liveLayer3Bytes = SVDBytes(location: 0x1EB, length: 0x3)
	private var liveLayer4Bytes = SVDBytes(location: 0x211, length: 0x3)

	var liveName: String
	var registrations: [SVDRegistration] = []
	var layer1ToneType: SVDPartType!
	var layer2ToneType: SVDPartType!
	var layer3ToneType: SVDPartType!
	var layer4ToneType: SVDPartType!
	var layer1Tone: SVDTone?
	var layer2Tone: SVDTone?
	var layer3Tone: SVDTone?
	var layer4Tone: SVDTone?

	init(svdFile: SVDFile, liveBytes: SVDBytes) {
		self.svdFile = svdFile

		let liveNameBytes = SVDBytes(location: liveBytes.location, length: kLiveNameLength)
		self.liveName = self.svdFile.stringFromBytes(liveNameBytes)

		self.liveLayer1Bytes.location += liveBytes.location
		self.liveLayer2Bytes.location += liveBytes.location
		self.liveLayer3Bytes.location += liveBytes.location
		self.liveLayer4Bytes.location += liveBytes.location
	}

	func addDependencyToRegistration(svdRegistration: SVDRegistration) {
		self.registrations.append(svdRegistration)
	}

	func findDependencies() {
		let liveLayer1MetaData = self.svdFile.unshiftedBytesFromBytes(self.liveLayer1Bytes)
		let liveLayer2MetaData = self.svdFile.unshiftedBytesFromBytes(self.liveLayer2Bytes)
		let liveLayer3MetaData = self.svdFile.unshiftedBytesFromBytes(self.liveLayer3Bytes)
		let liveLayer4MetaData = self.svdFile.unshiftedBytesFromBytes(self.liveLayer4Bytes)

		let liveLayer1LocationData = liveLayer1MetaData.subdataWithRange(NSRange(location: 1, length: 2))
		let liveLayer2LocationData = liveLayer2MetaData.subdataWithRange(NSRange(location: 1, length: 2))
		let liveLayer3LocationData = liveLayer3MetaData.subdataWithRange(NSRange(location: 1, length: 2))
		let liveLayer4LocationData = liveLayer4MetaData.subdataWithRange(NSRange(location: 1, length: 2))

		let liveLayer1Location = svdFile.numberFromData(liveLayer1LocationData)
		let liveLayer2Location = svdFile.numberFromData(liveLayer2LocationData)
		let liveLayer3Location = svdFile.numberFromData(liveLayer3LocationData)
		let liveLayer4Location = svdFile.numberFromData(liveLayer4LocationData)

		let liveLayer1TypeData = liveLayer1MetaData.subdataWithRange(NSRange(location: 0, length: 1))
		let liveLayer2TypeData = liveLayer2MetaData.subdataWithRange(NSRange(location: 0, length: 1))
		let liveLayer3TypeData = liveLayer3MetaData.subdataWithRange(NSRange(location: 0, length: 1))
		let liveLayer4TypeData = liveLayer4MetaData.subdataWithRange(NSRange(location: 0, length: 1))

		self.layer1ToneType = self.svdFile.partTypeFromData(liveLayer1TypeData)
		self.layer2ToneType = self.svdFile.partTypeFromData(liveLayer2TypeData)
		self.layer3ToneType = self.svdFile.partTypeFromData(liveLayer3TypeData)
		self.layer4ToneType = self.svdFile.partTypeFromData(liveLayer4TypeData)

		if self.layer1ToneType! == .Synth {
			self.layer1Tone = svdFile.tones[liveLayer1Location]
			self.layer1Tone?.addDependencyToLiveSet(self)
		}

		if self.layer2ToneType! == .Synth {
			self.layer2Tone = svdFile.tones[liveLayer2Location]
			self.layer2Tone?.addDependencyToLiveSet(self)
		}

		if self.layer3ToneType! == .Synth {
			self.layer3Tone = svdFile.tones[liveLayer3Location]
			self.layer3Tone?.addDependencyToLiveSet(self)
		}

		if self.layer4ToneType! == .Synth {
			self.layer4Tone = svdFile.tones[liveLayer4Location]
			self.layer4Tone?.addDependencyToLiveSet(self)
		}
	}
}
