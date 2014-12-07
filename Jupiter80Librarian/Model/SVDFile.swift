//
//  SVDFileModel.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 07/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

enum SVDFileFormat {
	case Unknown
	case Jupiter80
	case Jupiter50
}

struct SVDBytes {
	let location: Int
	let bytes: [UInt8]
}

private let kBytesSVD = SVDBytes(location: 2, bytes: [0x53, 0x56, 0x44])
private let kBytesREG = SVDBytes(location: 10, bytes: [0x52, 0x45, 0x47])
private let kBytesJPTR = SVDBytes(location: 14, bytes: [0x4a, 0x50, 0x54, 0x52])
private let kBytesJP50 = SVDBytes(location: 14, bytes: [0x4a, 0x50, 0x35, 0x30])

class SVDFile: NSObject {
	private var fileData: NSData
	private var fileFormat: SVDFileFormat
	private var isFileValid: Bool

	init(fileData: NSData) {
		self.fileData = fileData
		self.fileFormat = .Unknown
		self.isFileValid = false

		super.init()

		self.isFileValid = self.checkValidityOfData(self.fileData)
	}

	private func compareData(byteStruct: SVDBytes) -> Bool {
		let byteRange = NSRange(location: byteStruct.location, length: byteStruct.bytes.count)
		let byteData = self.fileData.subdataWithRange(byteRange)
		let byteCheck = NSData(bytes: byteStruct.bytes, length: byteStruct.bytes.count)

		return byteData.isEqualToData(byteCheck)
	}

	private func checkValidityOfData(fileData: NSData) -> Bool {
		// Check for string SVD
		let isSVDFile = self.compareData(kBytesSVD)

		if !isSVDFile {
			return false
		}

		// Check for string REG
		let isRegFile = self.compareData(kBytesREG)

		if isRegFile {
			// Check for string JPTR
			let isJupiter80File = self.compareData(kBytesJPTR)

			if isJupiter80File {
				self.fileFormat = .Jupiter80
			} else {
				// Check for string JP50
				let isJupiter50File = self.compareData(kBytesJP50)

				if isJupiter50File {
					self.fileFormat = .Jupiter50
				}
			}
		} else {
			return false
		}

		return true;
	}
}
