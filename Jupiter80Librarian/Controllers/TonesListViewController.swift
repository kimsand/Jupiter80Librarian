//
//  TonesListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class TonesListViewController: NSViewController {
	@IBOutlet var orderTextField: NSTextField!
	@IBOutlet var nameTextField: NSTextField!
	@IBOutlet var partial1TextField: NSTextField!
	@IBOutlet var partial2TextField: NSTextField!
	@IBOutlet var partial3TextField: NSTextField!

	@IBOutlet var tonesTableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var partial1Column: NSTableColumn!
	@IBOutlet var partial2Column: NSTableColumn!
	@IBOutlet var partial3Column: NSTableColumn!

	@IBOutlet var regsTableView: NSTableView!
	@IBOutlet var regNameColumn: NSTableColumn!
	@IBOutlet var regOrderColumn: NSTableColumn!

	@IBOutlet var livesTableView: NSTableView!
	@IBOutlet var liveNameColumn: NSTableColumn!
	@IBOutlet var liveOrderColumn: NSTableColumn!

	@IBOutlet var livesRegsCheckButton: NSButton!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var lastValidOrderText = ""

	var liveSets: [SVDLiveSet] = []
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
		} else if tableView == self.livesTableView {
			nrOfRows = self.liveSets.count
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
		} else if tableView == self.livesTableView {
			if tableColumn == self.liveNameColumn {
				columnValue = self.liveSets[row].liveName
			} else if tableColumn == self.liveOrderColumn {
				columnValue = "\(self.liveSets[row].orderNr)"
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func tableViewSelectionDidChange(aNotification: NSNotification) {
		let tableView = aNotification.object as NSTableView

		if tableView == self.tonesTableView {
			self.buildDependencyList()
		}
	}

	func buildDependencyList() {
		let selectedRowIndexes = self.tonesTableView.selectedRowIndexes
		var regSet = NSMutableSet(capacity: selectedRowIndexes.count)
		var liveSet = NSMutableSet(capacity: selectedRowIndexes.count)

		selectedRowIndexes.enumerateIndexesUsingBlock {
			(index: Int, finished: UnsafeMutablePointer<ObjCBool>) -> Void in
			let svdTone = self.svdFile!.tones[index]

			for reg in svdTone.registrations {
				if reg.regName != "INIT REGIST" {
					regSet.addObject(reg)
				}
			}

			for live in svdTone.liveSets {
				if live.liveName != "INIT LIVESET" {
					liveSet.addObject(live)
				}
			}

			// If selected, also add registrations from live sets using the tone
			if self.livesRegsCheckButton.state == NSOnState {
				for live in svdTone.liveSets {
					for reg in live.registrations {
						if reg.regName != "INIT REGIST" {
							regSet.addObject(reg)
						}
					}
				}
			}
		}

		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)

		var regList = regSet.allObjects as NSArray
		regList = regList.sortedArrayUsingDescriptors([sortDesc])

		var liveList = liveSet.allObjects as NSArray
		liveList = liveList.sortedArrayUsingDescriptors([sortDesc])

		self.registrations.removeAll(keepCapacity: true)

		for reg in regList {
			self.registrations.append(reg as SVDRegistration)
		}

		self.regsTableView.reloadData()

		self.liveSets.removeAll(keepCapacity: true)

		for live in liveList {
			self.liveSets.append(live as SVDLiveSet)
		}

		self.livesTableView.reloadData()
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

	@IBAction func liveRegsCheckButtonClicked(sender: NSButton) {
		self.buildDependencyList()
	}

	func svdFileDidUpdate(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.svdFile = self.model.openedSVDFile

			self.tonesTableView.reloadData()
		}
	}

	override func controlTextDidChange(obj: NSNotification) {
		if let textField = obj.object as? NSTextField {
			// The order field must contain a valid number
			if textField == self.orderTextField {
				var isValidTextField = false
				let text = textField.stringValue

				if let svdFile = self.svdFile? {
					if countElements(text) > 0 {
						if let order = text.toInt() {
							// The number is valid if it is between the min and max nr of live sets
							if order >= 1 && order <= svdFile.tones.count {
								isValidTextField = true
							}
						}
					}
					// The number is valid if the field is empty
					else {
						isValidTextField = true
					}
				}

				// Store the entered number if it is valid
				if isValidTextField == true {
					self.lastValidOrderText = text
				}
				// Restore the last valid number if the current is invalid
				else {
					textField.stringValue = self.lastValidOrderText
				}
			}
		}
	}

	override func controlTextDidEndEditing(obj: NSNotification) {
		if let textMovement = obj.userInfo?["NSTextMovement"] as? Int {
			// Only process the text field when the Return key was pressed
			if textMovement == NSReturnTextMovement {
				if let textField = obj.object as? NSTextField {
					var indices = [Int]()

					// The order field matches one and only one row number
					if textField == self.orderTextField {
						let text = textField.stringValue

						// Only process the text field when text was entered
						if countElements(text) > 0 {
							if let order = text.toInt() {
								let index = order - 1
								indices.append(index)
							}
						}
					}
					// The other fields match any number of rows containing the text
					// Only process the text field if an SVD file is open
					else if let svdFile = self.svdFile? {
						let text = textField.stringValue.lowercaseString

						// Only process the text field when text was entered
						if countElements(text) > 0 {
							var keyName = ""

							// Decide which property to look up dynamically by key path
							if textField == self.nameTextField {
								keyName = "toneName"
							} else if textField == self.partial1TextField {
								keyName = "partial1Name"
							} else if textField == self.partial2TextField {
								keyName = "partial2Name"
							} else if textField == self.partial3TextField {
								keyName = "partial3Name"
							}

							var index = 0

							for liveSet in svdFile.tones {
								if let name = liveSet.valueForKey(keyName) as String? {
									if name.lowercaseString.hasPrefix(text) {
										indices.append(index)
									}
								}

								index++
							}
						}
					}

					// If any rows were matched
					if indices.count > 0 {
						var indexSet = NSMutableIndexSet()

						for index in indices {
							indexSet.addIndex(index)
						}

						// Select all matched rows
						self.tonesTableView.selectRowIndexes(indexSet, byExtendingSelection: false)

						// Scroll to the first matched row
						if let index = indices.first? {
							let rect = self.tonesTableView.rectOfRow(index)
							self.tonesTableView.scrollPoint(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
						}
					}
				}
			}
		}
	}
}
