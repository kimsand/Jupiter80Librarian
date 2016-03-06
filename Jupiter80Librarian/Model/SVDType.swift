//
//  SVDType.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 06/03/16.
//  Copyright © 2016 Kim André Sand. All rights reserved.
//

import Cocoa

class SVDType: NSObject {
	internal let svdFile: SVDFile

	var orderNr: Int

	init(svdFile: SVDFile, orderNr: Int) {
		self.svdFile = svdFile
		self.orderNr = orderNr

		super.init()
	}
}
