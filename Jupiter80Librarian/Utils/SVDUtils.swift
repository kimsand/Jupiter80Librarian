//
//  SVDUtils.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

private let singleton = SVDUtils()

class SVDUtils: NSObject {
	class var singleton: SVDUtils {
		return self.singleton
	}

	class func compareData(data: NSData, loc: Int, bytes: [UInt8]) -> Bool {
		let subData = data.subdataWithRange(NSRange(location: loc, length: bytes.count))
		let subBytes = NSData(bytes: bytes, length: bytes.count)

		return subData.isEqualToData(subBytes)
	}

	class func checkValidityOfData(fileData: NSData) -> Bool {
		// Check for string SVD
		let isSVDFile = self.compareData(fileData, loc: 2, bytes: [0x53, 0x56, 0x44])

		if !isSVDFile {
			return false
		}

		// Check for string REG
		let isRegFile = self.compareData(fileData, loc: 10, bytes: [0x52, 0x45, 0x47])

		if isRegFile {
			var fileFormat = FileFormat.Unknown

			// Check for string JPTR
			let isJupiter80File = self.compareData(fileData, loc: 14, bytes: [0x4a, 0x50, 0x54, 0x52])

			if isJupiter80File {
				fileFormat = .Jupiter80
			} else {
				// Check for string JP50
				let isJupiter50File = self.compareData(fileData, loc: 14, bytes: [0x4a, 0x50, 0x35, 0x30])

				if isJupiter50File {
					fileFormat = .Jupiter50
				}
			}
		} else {
			return false
		}
		
		return true;
	}
}
