//
//  SVDLiveSet.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 09/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class SVDLiveSet: NSObject {
	private let svdFile: SVDFile

	private let liveNameLength = 0x10

	var liveName: String

	init(svdFile: SVDFile, liveBytes: SVDBytes) {
		self.svdFile = svdFile

		let liveNameBytes = SVDBytes(location: liveBytes.location, length: self.liveNameLength)
		self.liveName = self.svdFile.stringFromBytes(liveNameBytes)
	}
}
