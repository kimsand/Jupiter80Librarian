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
	private var liveLayer1Bytes = SVDBytes(location: 0x19F, length: 0x3)
	private var liveLayer2Bytes = SVDBytes(location: 0x1C5, length: 0x3)
	private var liveLayer3Bytes = SVDBytes(location: 0x1EB, length: 0x3)
	private var liveLayer4Bytes = SVDBytes(location: 0x211, length: 0x3)

	let liveName: String
	var registrations: [SVDRegistration] = []
	var layerToneTypes: [SVDPartType] = []
	var layerTones: [SVDTone?] = []
	var layerNames: [String?] = []
	var layer1Name: String!
	var layer2Name: String!
	var layer3Name: String!
	var layer4Name: String!

	init(svdFile: SVDFile, liveBytes: SVDBytes, orderNr: Int) {
        let liveNameBytes = SVDBytes(location: liveBytes.location, length: kLiveNameLength)
        liveName = svdFile.stringFromShiftedBytes(liveNameBytes)

        super.init(svdFile: svdFile, orderNr: orderNr)

		liveLayer1Bytes.location += liveBytes.location
		liveLayer2Bytes.location += liveBytes.location
		liveLayer3Bytes.location += liveBytes.location
		liveLayer4Bytes.location += liveBytes.location
	}

	func addDependencyToRegistration(_ svdRegistration: SVDRegistration) {
		// Ignore Registrations that are not initialized
		if svdRegistration.regName != "INIT REGIST" {
			registrations.append(svdRegistration)
		}
	}

	func findDependencies() {
		findDependenciesForLayerBytes(liveLayer1Bytes)
		findDependenciesForLayerBytes(liveLayer2Bytes)
		findDependenciesForLayerBytes(liveLayer3Bytes)
		findDependenciesForLayerBytes(liveLayer4Bytes)

		layer1Name = layerNames[0]
		layer2Name = layerNames[1]
		layer3Name = layerNames[2]
		layer4Name = layerNames[3]
	}

	private func findDependenciesForLayerBytes(_ layerBytes: SVDBytes) {
		let layerMetaData = svdFile.unshiftedBytesFromBytes(layerBytes)
		let layerLocationData = layerMetaData.subdata(in: 1..<1+2)
		let layerTypeData = layerMetaData.subdata(in: 0..<0+1)
		let layerToneType = svdFile.partTypeFromData(layerTypeData)

		layerToneTypes.append(layerToneType)

		if layerToneType.mainType == .synth {
			let layerLocation = svdFile.numberFromData(layerLocationData, nrOfBits: 7)
			let layerTone = svdFile.tones[layerLocation]
			layerTones.append(layerTone)
			layerNames.append(layerTone.toneName)

			layerTone.addDependencyToLiveSet(self)
		} else {
			layerTones.append(nil)
			let layerName = svdFile.partNameFromData(layerLocationData, partType: layerToneType)

			layerNames.append(layerName)
		}
	}
}
