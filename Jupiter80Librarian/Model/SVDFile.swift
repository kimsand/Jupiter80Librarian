//
//  SVDFile.swift
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

private let kBytesSVD = SVDBytes(location: 0x2, bytes: [0x53, 0x56, 0x44])
private let kBytesREG = SVDBytes(location: 0x10, bytes: [0x52, 0x45, 0x47])
private let kBytesJPTR = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x54, 0x52])
private let kBytesJP50 = SVDBytes(location: 0x14, bytes: [0x4A, 0x50, 0x35, 0x30])
private let kBytesVCL = SVDBytes(location: 0x40, bytes: [0x56, 0x43, 0x4C])
private let kBytesSYS = SVDBytes(location: 0x50, bytes: [0x53, 0x59, 0x53])
private let kBytesRBN = SVDBytes(location: 0x60, bytes: [0x52, 0x42, 0x4E])

private let kBytesRegLength = SVDBytes(location: 0x40, length: 4)

class SVDFile: NSObject {
	private let svdUtils: SVDUtils
	private var fileFormat: SVDFileFormat
	private var isFileValid: Bool
	private var headerOffset: Int

	init(fileData: NSData) {
		self.svdUtils = SVDUtils(fileData: fileData)
		self.fileFormat = .Unknown
		self.isFileValid = false
		self.headerOffset = 0x0

		super.init()

		self.isFileValid = self.checkValidityOfData(fileData)

		if !self.isFileValid {
			return;
		}

		self.findHeaderOffset()
		self.findPartLengths()
	}

	private func checkValidityOfData(fileData: NSData) -> Bool {
		// Check for string SVD
		let isSVDFile = self.svdUtils.compareData(kBytesSVD)

		if !isSVDFile {
			return false
		}

		// Check for string REG
		let isRegFile = self.svdUtils.compareData(kBytesREG)

		if isRegFile {
			// Check for string JPTR
			let isJupiter80File = self.svdUtils.compareData(kBytesJPTR)

			if isJupiter80File {
				self.fileFormat = .Jupiter80
			} else {
				// Check for string JP50
				let isJupiter50File = self.svdUtils.compareData(kBytesJP50)

				if isJupiter50File {
					self.fileFormat = .Jupiter50
				}
			}
		} else {
			return false
		}

		return true;
	}

	private func findHeaderOffset() {
		let hasVCLPart = self.svdUtils.compareData(kBytesVCL)

		if hasVCLPart {
			self.headerOffset += 0x10
		}

		let hasSYSPart = self.svdUtils.compareData(kBytesSYS)

		if hasSYSPart {
			self.headerOffset += 0x10
		}

		let hasRBNPart = self.svdUtils.compareData(kBytesRBN)

		if hasRBNPart {
			self.headerOffset += 0x10
		}
	}

	private func findPartLengths() {
		let nrOfRegs = self.svdUtils.numberFromBytes(kBytesRegLength)

		NSLog("Nr of regs: %d", nrOfRegs)
	}
}
