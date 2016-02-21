//
//  SVDTone.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 09/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

enum SVDOscType {
	case Unknown
	case Saw
	case Square
	case Pulse
	case Triangle
	case Sine
	case Noise
	case SuperSaw
	case PCM
}

class SVDTone: NSObject {
	private let svdFile: SVDFile

	private let toneNameLength = 0x0C
	private var partial1OscTypeBytes = SVDBytes(location: 0x1E, length: 0x1)
	private var partial2OscTypeBytes = SVDBytes(location: 0x4C, length: 0x1)
	private var partial3OscTypeBytes = SVDBytes(location: 0x7A, length: 0x1)
	private var partial1PCMBytes = SVDBytes(location: 0x45, length: 0x2)
	private var partial2PCMBytes = SVDBytes(location: 0x73, length: 0x2)
	private var partial3PCMBytes = SVDBytes(location: 0xA1, length: 0x2)

	var orderNr: Int
	var toneName: String
	var registrations: [SVDRegistration] = []
	var liveSets: [SVDLiveSet] = []

	var partialOscTypes: [SVDOscType] = []
	var partialNames: [String] = []
	var partial1Name: String!
	var partial2Name: String!
	var partial3Name: String!

	init(svdFile: SVDFile, toneBytes: SVDBytes, orderNr: Int) {
		self.svdFile = svdFile

		self.orderNr = orderNr

		let toneNameBytes = SVDBytes(location: toneBytes.location, length: self.toneNameLength)
		self.toneName = self.svdFile.stringFromShiftedBytes(toneNameBytes)

		self.partial1OscTypeBytes.location += toneBytes.location
		self.partial2OscTypeBytes.location += toneBytes.location
		self.partial3OscTypeBytes.location += toneBytes.location

		self.partial1PCMBytes.location += toneBytes.location
		self.partial2PCMBytes.location += toneBytes.location
		self.partial3PCMBytes.location += toneBytes.location

		super.init()

		self.findPartialsFromBytes(self.partial1OscTypeBytes, pcmBytes: self.partial1PCMBytes)
		self.findPartialsFromBytes(self.partial2OscTypeBytes, pcmBytes: self.partial2PCMBytes)
		self.findPartialsFromBytes(self.partial3OscTypeBytes, pcmBytes: self.partial3PCMBytes)

		self.partial1Name = self.partialNames[0]
		self.partial2Name = self.partialNames[1]
		self.partial3Name = self.partialNames[2]
	}

	func addDependencyToRegistration(svdRegistration: SVDRegistration) {
		// Ignore Registrations that are not initialized
		if svdRegistration.regName != "INIT REGIST" {
			self.registrations.append(svdRegistration)
		}
	}

	func addDependencyToLiveSet(svdLiveSet: SVDLiveSet) {
		self.liveSets.append(svdLiveSet)
	}

	func findPartialsFromBytes(byteStruct: SVDBytes, pcmBytes: SVDBytes) {
		let oscType = self.oscTypeFromBytes(byteStruct)
		self.partialOscTypes.append(oscType)

		var partialName: String
		if oscType == .PCM {
			partialName = self.svdFile.pcmNameFromNibbleBytes(pcmBytes)
		} else {
			partialName = self.partialNameFromOscType(oscType)
		}

		self.partialNames.append(partialName)
	}

	func oscTypeFromBytes(byteStruct: SVDBytes) -> SVDOscType {
		let number = self.svdFile.unshiftedNumberFromBytes(byteStruct, nrOfBits: 3)

		var oscType: SVDOscType

		switch number {
		case 0: oscType = .Saw
		case 1: oscType = .Square
		case 2: oscType = .Pulse
		case 3: oscType = .Triangle
		case 4: oscType = .Sine
		case 5: oscType = .Noise
		case 6: oscType = .SuperSaw
		case 7: oscType = .PCM
		default: oscType = .Unknown
		}

		return oscType
	}

	func partialNameFromOscType(oscType: SVDOscType) -> String {
		var name: String

		switch oscType {
		case .Saw: name = "Saw"
		case .Square: name = "Square"
		case .Pulse: name = "Pulse"
		case .Triangle: name = "Triangle"
		case .Sine: name = "Sine"
		case .Noise: name = "Noise"
		case .SuperSaw: name = "SuperSaw"
		case .PCM: name = "PCM"
		default: name = "Unknown"
		}

		return name
	}
}
