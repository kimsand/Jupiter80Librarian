//
//  TonesListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class TonesListViewController: NSViewController {
	enum DependencySegment: Int {
		case All = 1
		case Selected
		case Used
		case Unused
	}

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

	@IBOutlet var dependencySegmentedControl: NSSegmentedControl!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var lastValidOrderText = ""

	var tableData: [SVDTone] = []
	var livesTableData: [SVDLiveSet] = []
	var regsTableData: [SVDRegistration] = []

	// MARK: Lifecycle

	override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
		super.viewDidLoad()

		self.updateSVD()
	}

	// MARK: Member methods

	func updateSVD() {
		self.svdFile = self.model.openedSVDFile

		if let svdFile = self.svdFile {
			self.updateTableFromList(svdFile.tones)
		}
	}

	func indexSetFromTones(tones: [SVDTone]) -> NSIndexSet {
		let indexSet = NSMutableIndexSet()

		// Keep selection when updating the list view
		for tone in Model.singleton.selectedTones {
			let index = self.tableData.indexOf(tone)

			if index != nil {
				indexSet.addIndex(index!)
			}
		}

		return indexSet
	}

	func updateTableFromList(tones: [SVDTone]) {
		self.tableData.removeAll(keepCapacity: true)
		self.tableData += tones
		self.tonesTableView.reloadData()

		let indexSet = self.indexSetFromTones(tones)
		self.tonesTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
	}

	func buildDependencyList() {
		let selectedRowIndexes = self.indexSetFromTones(Model.singleton.selectedTones)
		let regSet = NSMutableSet(capacity: selectedRowIndexes.count)
		let liveSet = NSMutableSet(capacity: selectedRowIndexes.count)

		selectedRowIndexes.enumerateIndexesUsingBlock {
			(index: Int, finished: UnsafeMutablePointer<ObjCBool>) -> Void in
			let svdTone = self.tableData[index]

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

		let regList = (regSet.allObjects as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDRegistration]
		let liveList = (liveSet.allObjects as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDLiveSet]

		self.regsTableData.removeAll(keepCapacity: true)
		self.regsTableData += regList

		self.regsTableView.reloadData()

		self.livesTableData.removeAll(keepCapacity: true)
		self.livesTableData += liveList

		self.livesTableView.reloadData()
	}

	func buildSelectionList() {
		let selectedRowIndexes = self.tonesTableView.selectedRowIndexes
		var selectedTones: [SVDTone] = []

		for index in selectedRowIndexes {
			let svdTone = self.tableData[index]
			selectedTones.append(svdTone)
		}

		var unselectedTones: [SVDTone] = []

		for tone in Model.singleton.selectedTones {
			if selectedTones.indexOf(tone) == nil
				&& self.tableData.indexOf(tone) != nil {
					unselectedTones.append(tone)
			}
		}

		// Add rows that are newly selected
		for tone in selectedTones {
			if unselectedTones.indexOf(tone) == nil {
				if Model.singleton.selectedTones.indexOf(tone) == nil {
					Model.singleton.selectedTones.append(tone)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedTones {
			let foundIndex = Model.singleton.selectedTones.indexOf(liveSet)

			if foundIndex != nil {
				Model.singleton.selectedTones.removeAtIndex(foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		Model.singleton.selectedTones = (Model.singleton.selectedTones as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDTone]
	}

	func filterDependencies() {
		var filteredTones: [SVDTone] = []

		let selectedSegment = self.dependencySegmentedControl.selectedSegment
		let segmentTag = (self.dependencySegmentedControl.cell as! NSSegmentedCell).tagForSegment(selectedSegment)

		if let svdFile = self.svdFile {
			switch segmentTag {
			case DependencySegment.All.rawValue:
				filteredTones = svdFile.tones
			case DependencySegment.Selected.rawValue:
				for svdTone in Model.singleton.selectedTones {
					filteredTones.append(svdTone)
				}
			case DependencySegment.Used.rawValue:
				for svdTone in svdFile.tones {
					if svdTone.liveSets.count > 0
					|| svdTone.registrations.count > 0 {
						filteredTones.append(svdTone)
					}
				}
			case DependencySegment.Unused.rawValue:
				for svdTone in svdFile.tones {
					if svdTone.liveSets.count <= 0
					&& svdTone.registrations.count <= 0 {
						filteredTones.append(svdTone)
					}
				}
			default:
				return
			}
		}

		self.updateTableFromList(filteredTones)
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

	// MARK: Table view

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == self.tonesTableView {
			nrOfRows = self.tableData.count
		} else if tableView == self.regsTableView {
			nrOfRows = self.regsTableData.count
		} else if tableView == self.livesTableView {
			nrOfRows = self.livesTableData.count
		}

		return nrOfRows
	}

	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		let result = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner:self) as! NSTableCellView
		result.textField?.textColor = NSColor.blackColor()

		var columnValue: String = ""
		var textColor = NSColor.blackColor()

		if tableView == self.tonesTableView {
			let svdTone = self.tableData[row]

			if tableColumn == self.nameColumn {
				columnValue = svdTone.toneName
				textColor = self.textColorForToneName(columnValue)
			} else if tableColumn == self.orderColumn {
				columnValue = "\(svdTone.orderNr)"
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
				columnValue = self.regsTableData[row].regName
			} else if tableColumn == self.regOrderColumn {
				columnValue = "\(self.regsTableData[row].orderNr)"
			}
		} else if tableView == self.livesTableView {
			if tableColumn == self.liveNameColumn {
				columnValue = self.livesTableData[row].liveName
			} else if tableColumn == self.liveOrderColumn {
				columnValue = "\(self.livesTableData[row].orderNr)"
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [AnyObject]) {
		if tableView == self.livesTableView {
			self.livesTableData = (self.livesTableData as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as! [SVDLiveSet]
		} else if tableView == self.regsTableView {
			self.regsTableData = (self.regsTableData as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as! [SVDRegistration]
		} else {
			self.tableData = (self.tableData as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as! [SVDTone]
		}

		tableView.reloadData()
	}

	func tableViewSelectionDidChange(notification: NSNotification) {
		let tableView = notification.object as! NSTableView

		if tableView == self.tonesTableView {
			self.buildSelectionList()
			self.buildDependencyList()
		}
	}

	// MARK: Text field

	override func controlTextDidChange(obj: NSNotification) {
		if let textField = obj.object as? NSTextField {
			// The order field must contain a valid number
			if textField == self.orderTextField {
				var isValidTextField = false
				let text = textField.stringValue

				if self.tableData.count > 0 {
					if text.characters.count > 0 {
						if let order = Int(text) {
							// The number is valid if it is between the min and max nr of rows
							if order >= 1 && order <= self.tableData.count {
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
						if text.characters.count > 0 {
							var index = 0

							if let order = Int(text) {
								for svdReg in self.tableData {
									if svdReg.orderNr == order {
										indices.append(index)
										break;
									}

									index++
								}
							}
						}
					}
					// The other fields match any number of rows containing the text
					// Only process the text field if an SVD file is open
					else if self.tableData.count > 0 {
						let text = textField.stringValue.lowercaseString

						// Only process the text field when text was entered
						if text.characters.count > 0 {
							var index = 0

							for svdTone in self.tableData {
								var name: String

								if textField == self.nameTextField {
									name = svdTone.toneName
								} else if textField == self.partial1TextField {
									name = svdTone.partial1Name
								} else if textField == self.partial2TextField {
									name = svdTone.partial2Name
								} else if textField == self.partial3TextField {
									name = svdTone.partial3Name
								} else {
									break // unsupported field
								}

								if name.lowercaseString.hasPrefix(text) {
									indices.append(index)
								}

								index++
							}
						}
					}

					// If any rows were matched
					if indices.count > 0 {
						let indexSet = NSMutableIndexSet()

						for index in indices {
							indexSet.addIndex(index)
						}

						// Select all matched rows
						self.tonesTableView.selectRowIndexes(indexSet, byExtendingSelection: false)

						// Scroll to the first matched row
						if let index = indices.first {
							let rect = self.tonesTableView.rectOfRow(index)
							self.tonesTableView.scrollPoint(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
						}
					}
				}
			}
		}
	}

	// MARK: Actions

	@IBAction func liveRegsCheckButtonClicked(sender: NSButton) {
		self.buildDependencyList()
	}

	@IBAction func dependencySegmentedControlAction(sender: NSSegmentedControl) {
		self.filterDependencies()
	}

	// MARK: Notifications

	func svdFileDidUpdate(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.updateSVD()
		}
	}
}
