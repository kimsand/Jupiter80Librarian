//
//  TonesListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class TonesListViewController: NSViewController {
	@IBOutlet var tonesTableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var partial1Column: NSTableColumn!
	@IBOutlet var partial2Column: NSTableColumn!
	@IBOutlet var partial3Column: NSTableColumn!

	@IBOutlet var regsTableView: NSTableView!
	@IBOutlet var regNameColumn: NSTableColumn!
	@IBOutlet var regOrderColumn: NSTableColumn!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var registrations: [SVDRegistration] = []

	override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
		super.viewDidLoad()

		self.svdFile = self.model.openedSVDFile
		self.tonesTableView.reloadData()
	}

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == self.tonesTableView {
			if self.svdFile != nil {
				nrOfRows = self.svdFile!.tones.count
			}
		} else if tableView == self.regsTableView {
			nrOfRows = self.registrations.count
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

		if tableView == self.tonesTableView {
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

				columnValue = svdTone.partialNames[partialNr]
				let oscType = svdTone.partialOscTypes[partialNr]
				textColor = self.textColorForOscType(oscType)
			}
		} else if tableView == self.regsTableView {
			if tableColumn == self.regNameColumn {
				columnValue = self.registrations[row].regName
			} else if tableColumn == self.regOrderColumn {
				columnValue = "\(self.registrations[row].orderNr)"
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func tableViewSelectionDidChange(aNotification: NSNotification) {
		let tableView = aNotification.object as NSTableView

		if tableView == self.tonesTableView {
			var regSet = NSMutableSet(capacity: tableView.selectedRowIndexes.count)

			tableView.selectedRowIndexes.enumerateIndexesUsingBlock {
				(index: Int, finished: UnsafeMutablePointer<ObjCBool>) -> Void in
				let svdTone = self.svdFile!.tones[index]

				regSet.addObjectsFromArray(svdTone.registrations)
			}

			var regList = regSet.allObjects as NSArray
			let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
			regList = regList.sortedArrayUsingDescriptors([sortDesc])

			self.registrations.removeAll(keepCapacity: true)

			for reg in regList {
				self.registrations.append(reg as SVDRegistration)
			}

			self.regsTableView.reloadData()
		}
	}

	func textColorForToneName(toneName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		self.isInitSound = false

		if toneName == "INIT SYNTH" {
			textColor = .lightGrayColor()
			self.isInitSound = true
		}

		return textColor
	}

	func textColorForOscType(oscType: SVDOscType) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true {
			textColor = .lightGrayColor()
		} else if oscType == .PCM {
			textColor = .purpleColor()
		} else {
			textColor = .blueColor()
		}

		return textColor
	}

	func svdFileDidUpdate(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.svdFile = self.model.openedSVDFile

			self.tonesTableView.reloadData()
		}
	}
}
