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
		// Retrieve to get the @"MyView" from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		var result = tableView.makeViewWithIdentifier("RegListCell", owner:self) as NSTableCellView

		// Set the stringValue of the cell's text field to the nameArray value at row
		let svdReg = self.svdFile!.registrations[row]
		result.textField?.stringValue = svdReg.regName

		// Return the result
		return result
	}
}
