//
//  SVDTone.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 09/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class SVDTone: NSObject {
	private let svdFile: SVDFile

	private let toneNameLength = 0x0C

	var toneName: String

	init(svdFile: SVDFile, toneBytes: SVDBytes) {
		self.svdFile = svdFile

		let toneNameBytes = SVDBytes(location: toneBytes.location, length: self.toneNameLength)
		self.toneName = self.svdFile.stringFromBytes(toneNameBytes)

		NSLog("Tone name: '%@'", self.toneName)
	}
}
