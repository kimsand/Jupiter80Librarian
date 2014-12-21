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

	var orderNr: Int
	var liveName: String
	var registrations: [SVDRegistration] = []
	var layerToneTypes: [SVDPartType] = []
	var layerTones: [SVDTone?] = []
	var layerNames: [String?] = []

	init(svdFile: SVDFile, liveBytes: SVDBytes, orderNr: Int) {
		self.svdFile = svdFile

		self.orderNr = orderNr

		let liveNameBytes = SVDBytes(location: liveBytes.location, length: kLiveNameLength)
		self.liveName = self.svdFile.stringFromShiftedBytes(liveNameBytes)

		self.liveLayer1Bytes.location += liveBytes.location
		self.liveLayer2Bytes.location += liveBytes.location
		self.liveLayer3Bytes.location += liveBytes.location
		self.liveLayer4Bytes.location += liveBytes.location
	}

	func addDependencyToRegistration(svdRegistration: SVDRegistration) {
		self.registrations.append(svdRegistration)
	}

	func findDependencies() {
		self.findDependenciesForLayerBytes(self.liveLayer1Bytes)
		self.findDependenciesForLayerBytes(self.liveLayer2Bytes)
		self.findDependenciesForLayerBytes(self.liveLayer3Bytes)
		self.findDependenciesForLayerBytes(self.liveLayer4Bytes)
	}

	func findDependenciesForLayerBytes(layerBytes: SVDBytes) {
		let layerMetaData = self.svdFile.unshiftedBytesFromBytes(layerBytes)
		let layerLocationData = layerMetaData.subdataWithRange(NSRange(location: 1, length: 2))
		let layerTypeData = layerMetaData.subdataWithRange(NSRange(location: 0, length: 1))
		let layerToneType = self.svdFile.partTypeFromData(layerTypeData)

		self.layerToneTypes.append(layerToneType)

		if layerToneType.mainType == .Synth {
			let layerLocation = svdFile.numberFromData(layerLocationData, nrOfBits: 7)
			let layerTone = svdFile.tones[layerLocation]
			self.layerTones.append(layerTone)
			self.layerNames.append(nil)

			layerTone.addDependencyToLiveSet(self)
		} else {
			self.layerTones.append(nil)
			let layerName = svdFile.partNameFromData(layerLocationData, partType: layerToneType)

			self.layerNames.append(layerName)
		}
	}
}
