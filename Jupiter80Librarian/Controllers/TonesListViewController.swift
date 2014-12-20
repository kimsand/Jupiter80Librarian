//
//  TonesListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class TonesListViewController: NSViewController {
	@IBOutlet var tableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var partial1Column: NSTableColumn!
	@IBOutlet var partial2Column: NSTableColumn!
	@IBOutlet var partial3Column: NSTableColumn!

	var model = Model.singleton
	var svdFile: SVDFile?

	override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
		super.viewDidLoad()

		self.svdFile = self.model.openedSVDFile
		self.tableView.reloadData()
	}

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if self.svdFile != nil {
			nrOfRows = self.svdFile!.tones.count
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

		let svdTone = self.svdFile!.tones[row]

		if tableColumn == self.nameColumn {
			columnValue = svdTone.toneName
			textColor = self.textColorForToneName(columnValue)
		} else if tableColumn == self.orderColumn {
			columnValue = "\(row + 1)"
		} else if tableColumn == self.partial1Column
			|| tableColumn == self.partial2Column
			|| tableColumn == self.partial3Column
		{
			var partialNr: Int

			if tableColumn == self.partial1Column {
				partialNr = 0
			} else if tableColumn == self.partial2Column {
				partialNr = 1
			} else {
				partialNr = 2
			}

			columnValue = svdTone.partialNames[partialNr]!
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func textColorForToneName(toneName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		if toneName == "INIT SYNTH" {
			textColor = .lightGrayColor()
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
