//
//  SVDLiveSet.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 09/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

private let kLiveNameLength = 0x10

class SVDLiveSet: SVDType {
	fileprivate var liveLayer1Bytes = SVDBytes(location: 0x19F, length: 0x3)
	fileprivate var liveLayer2Bytes = SVDBytes(location: 0x1C5, length: 0x3)
	fileprivate var liveLayer3Bytes = SVDBytes(location: 0x1EB, length: 0x3)
	fileprivate var liveLayer4Bytes = SVDBytes(location: 0x211, length: 0x3)

	var liveName: String!
	var registrations: [SVDRegistration] = []
	var layerToneTypes: [SVDPartType] = []
	var layerTones: [SVDTone?] = []
	var layerNames: [String?] = []
	var layer1Name: String!
	var layer2Name: String!
	var layer3Name: String!
	var layer4Name: String!

	init(svdFile: SVDFile, liveBytes: SVDBytes, orderNr: Int) {
		super.init(svdFile: svdFile, orderNr: orderNr)

		let liveNameBytes = SVDBytes(location: liveBytes.location, length: kLiveNameLength)
		self.liveName = self.svdFile.stringFromShiftedBytes(liveNameBytes)

		self.liveLayer1Bytes.location += liveBytes.location
		self.liveLayer2Bytes.location += liveBytes.location
		self.liveLayer3Bytes.location += liveBytes.location
		self.liveLayer4Bytes.location += liveBytes.location
	}

	func addDependencyToRegistration(_ svdRegistration: SVDRegistration) {
		// Ignore Registrations that are not initialized
		if svdRegistration.regName != "INIT REGIST" {
			self.registrations.append(svdRegistration)
		}
	}

	func findDependencies() {
		self.findDependenciesForLayerBytes(self.liveLayer1Bytes)
		self.findDependenciesForLayerBytes(self.liveLayer2Bytes)
		self.findDependenciesForLayerBytes(self.liveLayer3Bytes)
		self.findDependenciesForLayerBytes(self.liveLayer4Bytes)

		self.layer1Name = self.layerNames[0]
		self.layer2Name = self.layerNames[1]
		self.layer3Name = self.layerNames[2]
		self.layer4Name = self.layerNames[3]
	}

	func findDependenciesForLayerBytes(_ layerBytes: SVDBytes) {
		let layerMetaData = self.svdFile.unshiftedBytesFromBytes(layerBytes)
		let layerLocationData = layerMetaData.subdata(in: 1..<1+2)
		let layerTypeData = layerMetaData.subdata(in: 0..<0+1)
		let layerToneType = self.svdFile.partTypeFromData(layerTypeData)

		self.layerToneTypes.append(layerToneType)

		if layerToneType.mainType == .synth {
			let layerLocation = svdFile.numberFromData(layerLocationData, nrOfBits: 7)
			let layerTone = svdFile.tones[layerLocation]
			self.layerTones.append(layerTone)
			self.layerNames.append(layerTone.toneName)

			layerTone.addDependencyToLiveSet(self)
		} else {
			self.layerTones.append(nil)
			let layerName = svdFile.partNameFromData(layerLocationData, partType: layerToneType)

			self.layerNames.append(layerName)
		}
	}
}
