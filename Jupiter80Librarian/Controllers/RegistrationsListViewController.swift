//
//  RegistrationsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class RegistrationsListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var tableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var upperColumn: NSTableColumn!
	@IBOutlet var lowerColumn: NSTableColumn!
	@IBOutlet var soloColumn: NSTableColumn!
	@IBOutlet var percColumn: NSTableColumn!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

    override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
        super.viewDidLoad()

		self.svdFile = self.model.openedSVDFile
		self.tableView.reloadData()
	}

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if self.svdFile != nil {
			nrOfRows = self.svdFile!.registrations.count
		}

		return nrOfRows
	}

	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		var result = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner:self) as NSTableCellView
		result.textField?.textColor = NSColor.blackColor()

		var columnValue: String = ""
		var textColor = NSColor.blackColor()

		let svdReg = self.svdFile!.registrations[row]

		if tableColumn == self.nameColumn {
			columnValue = svdReg.regName
			textColor = self.textColorForRegistrationName(columnValue)
		} else if tableColumn == self.orderColumn {
			columnValue = "\(row + 1)"
		} else if tableColumn == self.upperColumn {
			columnValue = svdReg.upperLiveSet.liveName
			textColor = self.textColorForLiveSetName(columnValue)
		} else if tableColumn == self.lowerColumn {
			if self.svdFile != nil {
				if self.svdFile!.fileFormat == .Jupiter80 {
					columnValue = svdReg.lowerLiveSet.liveName
					textColor = self.textColorForLiveSetName(columnValue)
				} else {
					columnValue = "NOT USED"
					textColor = NSColor.lightGrayColor()
				}
			}
		} else if tableColumn == self.soloColumn {
			if svdReg.soloTone != nil {
				columnValue = svdReg.soloTone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if svdReg.soloName != nil {
				columnValue = svdReg.soloName!
				textColor = self.textColorForPartType(svdReg.soloToneType!)
			}
		} else if tableColumn == self.percColumn {
			if svdReg.percTone != nil {
				columnValue = svdReg.percTone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if svdReg.percName != nil {
				columnValue = svdReg.percName!
				textColor = self.textColorForPartType(svdReg.percToneType!)
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func textColorForPartType(partType: SVDPartType) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true {
			textColor = .lightGrayColor()
		} else if partType.mainType == .Acoustic {
			textColor = .purpleColor()
		} else if partType.mainType == .DrumSet {
			textColor = .blueColor()
		}

		return textColor
	}

	func textColorForToneName(toneName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true || toneName == "INIT SYNTH" {
			textColor = .lightGrayColor()
		}

		return textColor
	}

	func textColorForLiveSetName(liveName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true || liveName == "INIT LIVESET" {
			textColor = .lightGrayColor()
		}

		return textColor
	}

	func textColorForRegistrationName(regName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		self.isInitSound = false

		if regName == "INIT REGIST" {
			textColor = .lightGrayColor()
			self.isInitSound = true
		}

		return textColor
	}

	func svdFileDidUpdate(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.svdFile = self.model.openedSVDFile

			self.tableView.reloadData()
		}
	}
}
