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
	private let svdUtils: SVDUtils
	var regName: String = ""

	init(svdUtils: SVDUtils, regBytes: SVDBytes) {
		self.svdUtils = svdUtils

		let regNameBytes = SVDBytes(location: regBytes.location, length: kRegNameLength)
		self.regName = self.svdUtils.stringFromBytes(regNameBytes)

		NSLog("Registration name: '%@'", self.regName)
	}
}
