//
//  SVDTone.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 09/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

enum SVDOscType {
	case unknown
	case saw
	case square
	case pulse
	case triangle
	case sine
	case noise
	case superSaw
	case pcm
}

class SVDTone: SVDType {
	private let toneNameLength = 0x0C
	private var partial1OscTypeBytes = SVDBytes(location: 0x1E, length: 0x1)
	private var partial2OscTypeBytes = SVDBytes(location: 0x4C, length: 0x1)
	private var partial3OscTypeBytes = SVDBytes(location: 0x7A, length: 0x1)
	private var partial1PCMBytes = SVDBytes(location: 0x45, length: 0x2)
	private var partial2PCMBytes = SVDBytes(location: 0x73, length: 0x2)
	private var partial3PCMBytes = SVDBytes(location: 0xA1, length: 0x2)

	let toneName: String
	var registrations: [SVDRegistration] = []
	var liveSets: [SVDLiveSet] = []

	var partialOscTypes: [SVDOscType] = []
	var partialNames: [String] = []
	var partial1Name: String!
	var partial2Name: String!
	var partial3Name: String!

	init(svdFile: SVDFile, toneBytes: SVDBytes, orderNr: Int) {
        let toneNameBytes = SVDBytes(location: toneBytes.location, length: toneNameLength)
        toneName = svdFile.stringFromShiftedBytes(toneNameBytes)

        super.init(svdFile: svdFile, orderNr: orderNr)

		partial1OscTypeBytes.location += toneBytes.location
		partial2OscTypeBytes.location += toneBytes.location
		partial3OscTypeBytes.location += toneBytes.location

		partial1PCMBytes.location += toneBytes.location
		partial2PCMBytes.location += toneBytes.location
		partial3PCMBytes.location += toneBytes.location

		findPartialsFromBytes(partial1OscTypeBytes, pcmBytes: partial1PCMBytes)
		findPartialsFromBytes(partial2OscTypeBytes, pcmBytes: partial2PCMBytes)
		findPartialsFromBytes(partial3OscTypeBytes, pcmBytes: partial3PCMBytes)

		partial1Name = partialNames[0]
		partial2Name = partialNames[1]
		partial3Name = partialNames[2]
	}

	func addDependencyToRegistration(_ svdRegistration: SVDRegistration) {
		// Ignore Registrations that are not initialized
		if svdRegistration.regName != "INIT REGIST" {
			registrations.append(svdRegistration)
		}
	}

	func addDependencyToLiveSet(_ svdLiveSet: SVDLiveSet) {
		// Ignore Live Sets that are not initialized
		if svdLiveSet.liveName != "INIT LIVESET" {
			liveSets.append(svdLiveSet)
		}
	}

	func findPartialsFromBytes(_ byteStruct: SVDBytes, pcmBytes: SVDBytes) {
		let oscType = oscTypeFromBytes(byteStruct)
		partialOscTypes.append(oscType)

		var partialName: String
		if oscType == .pcm {
			partialName = svdFile.pcmNameFromNibbleBytes(pcmBytes)
		} else {
			partialName = partialNameFromOscType(oscType)
		}

		partialNames.append(partialName)
	}

	func oscTypeFromBytes(_ byteStruct: SVDBytes) -> SVDOscType {
		let number = svdFile.unshiftedNumberFromBytes(byteStruct, nrOfBits: 3)

		var oscType: SVDOscType

		switch number {
		case 0: oscType = .saw
		case 1: oscType = .square
		case 2: oscType = .pulse
		case 3: oscType = .triangle
		case 4: oscType = .sine
		case 5: oscType = .noise
		case 6: oscType = .superSaw
		case 7: oscType = .pcm
		default: oscType = .unknown
		}

		return oscType
	}

	func partialNameFromOscType(_ oscType: SVDOscType) -> String {
		var name: String

		switch oscType {
		case .saw: name = "Saw"
		case .square: name = "Square"
		case .pulse: name = "Pulse"
		case .triangle: name = "Triangle"
		case .sine: name = "Sine"
		case .noise: name = "Noise"
		case .superSaw: name = "SuperSaw"
		case .pcm: name = "PCM"
		default: name = "Unknown"
		}

		return name
	}
}
