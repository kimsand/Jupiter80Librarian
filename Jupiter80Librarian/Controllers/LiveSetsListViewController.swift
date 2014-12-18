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
		} else if tableColumn == self.layer1Column
			|| tableColumn == self.layer2Column
			|| tableColumn == self.layer3Column
			|| tableColumn == self.layer4Column
		{
			var layerNr: Int

			if tableColumn == self.layer1Column {
				layerNr = 0
			} else if tableColumn == self.layer2Column {
				layerNr = 1
			} else if tableColumn == self.layer3Column {
				layerNr = 2
			} else {
				layerNr = 3
			}

			let layerToneType: SVDPartType = svdLive.layerToneTypes[layerNr]
			let layerTone: SVDTone? = svdLive.layerTones[layerNr]
			let layerName: String? = svdLive.layerNames[layerNr]

			if layerTone != nil {
				columnValue = layerTone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if layerName != nil {
				columnValue = layerName!
				textColor = self.textColorForPartType(layerToneType)
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