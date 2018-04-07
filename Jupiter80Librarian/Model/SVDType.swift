//
//  SVDType.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 06/03/16.
//  Copyright © 2016 Kim André Sand. All rights reserved.
//

import Cocoa

// TODO: Use an enum to indicate subtype until Interface Builder supports generics
enum SVDSubType {
	case registration
	case liveSet
	case tone
}

class SVDType: NSObject {
	internal let svdFile: SVDFile

	@objc var orderNr: Int

	init(svdFile: SVDFile, orderNr: Int) {
		self.svdFile = svdFile
		self.orderNr = orderNr

		super.init()
	}
}
