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

    override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
        super.viewDidLoad()
	}

	func svdFileDidUpdate(notification: NSNotification) {
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
		var result = tableView.makeViewWithIdentifier("RegListCell", owner:self) as NSTableCellView
		result.textField?.stringValue = ""

		let svdReg = self.svdFile!.registrations[row]

		if tableColumn == self.nameColumn {
			result.textField?.stringValue = svdReg.regName
		} else if tableColumn == self.orderColumn {
			result.textField?.stringValue = "\(row + 1)"
		} else if tableColumn == self.upperColumn {
			result.textField?.stringValue = svdReg.upperLiveSet.liveName
		} else if tableColumn == self.lowerColumn {
			result.textField?.stringValue = svdReg.lowerLiveSet.liveName
		} else if tableColumn == self.soloColumn {
			if svdReg.soloTone != nil {
				result.textField?.stringValue = svdReg.soloTone!.toneName
			}
		} else if tableColumn == self.percColumn {
			if svdReg.percTone != nil {
				result.textField?.stringValue = svdReg.percTone!.toneName
			}
		}

		return result
	}
}
