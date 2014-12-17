//
//  LiveSetsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class LiveSetsListViewController: NSViewController {
	@IBOutlet var tableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var layer1Column: NSTableColumn!
	@IBOutlet var layer2Column: NSTableColumn!
	@IBOutlet var layer3Column: NSTableColumn!
	@IBOutlet var layer4Column: NSTableColumn!

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
			nrOfRows = self.svdFile!.liveSets.count
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

		let svdLive = self.svdFile!.liveSets[row]

		if tableColumn == self.nameColumn {
			columnValue = svdLive.liveName
			textColor = self.textColorForLiveSetName(columnValue)
		} else if tableColumn == self.orderColumn {
			columnValue = "\(row + 1)"
		} else if tableColumn == self.layer1Column {
			if svdLive.layer1Tone != nil {
				columnValue = svdLive.layer1Tone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if svdLive.layer1Name != nil {
				columnValue = svdLive.layer1Name!
				textColor = self.textColorForPartType(svdLive.layer1ToneType!)
			}
		} else if tableColumn == self.layer2Column {
			if svdLive.layer2Tone != nil {
				columnValue = svdLive.layer2Tone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if svdLive.layer2Name != nil {
				columnValue = svdLive.layer2Name!
				textColor = self.textColorForPartType(svdLive.layer2ToneType!)
			}
		} else if tableColumn == self.layer3Column {
			if svdLive.layer3Tone != nil {
				columnValue = svdLive.layer3Tone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if svdLive.layer3Name != nil {
				columnValue = svdLive.layer3Name!
				textColor = self.textColorForPartType(svdLive.layer3ToneType!)
			}
		} else if tableColumn == self.layer4Column {
			if svdLive.layer4Tone != nil {
				columnValue = svdLive.layer4Tone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if svdLive.layer4Name != nil {
				columnValue = svdLive.layer4Name!
				textColor = self.textColorForPartType(svdLive.layer4ToneType!)
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
		} else if partType == .Acoustic {
			textColor = .purpleColor()
		} else if partType == .DrumSet {
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

		self.isInitSound = false

		if liveName == "INIT LIVESET" {
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
