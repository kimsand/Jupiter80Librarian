//
//  LiveSetsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class LiveSetsListViewController: NSViewController {
	@IBOutlet var orderTextField: NSTextField!
	@IBOutlet var nameTextField: NSTextField!
	@IBOutlet var layer1TextField: NSTextField!
	@IBOutlet var layer2TextField: NSTextField!
	@IBOutlet var layer3TextField: NSTextField!
	@IBOutlet var layer4TextField: NSTextField!

	@IBOutlet var livesTableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var layer1Column: NSTableColumn!
	@IBOutlet var layer2Column: NSTableColumn!
	@IBOutlet var layer3Column: NSTableColumn!
	@IBOutlet var layer4Column: NSTableColumn!

	@IBOutlet var regsTableView: NSTableView!
	@IBOutlet var regNameColumn: NSTableColumn!
	@IBOutlet var regOrderColumn: NSTableColumn!

	@IBOutlet var dependencySegmentedControl: NSSegmentedControl!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var lastValidOrderText = ""

	var tableData: [SVDLiveSet] = []
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
			self.updateTableFromList(svdFile.liveSets)
		}
	}

	func updateTableFromList(liveSets: [SVDLiveSet]) {
		self.tableData.removeAll(keepCapacity: true)
		self.tableData += liveSets
		self.livesTableView.reloadData()
	}

	func buildDependencyList() {
		let selectedRowIndexes = self.livesTableView.selectedRowIndexes
		let regSet = NSMutableSet(capacity: selectedRowIndexes.count)

		selectedRowIndexes.enumerateIndexesUsingBlock {
			(index: Int, finished: UnsafeMutablePointer<ObjCBool>) -> Void in
			let svdLive = self.tableData[index]

			for reg in svdLive.registrations {
				if reg.regName != "INIT REGIST" {
					regSet.addObject(reg)
				}
			}
		}

		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		let regList = (regSet.allObjects as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDRegistration]

		self.regsTableData.removeAll(keepCapacity: true)
		self.regsTableData += regList

		self.regsTableView.reloadData()
	}

	func filterDependencies() {
		var filteredLiveSets: [SVDLiveSet] = []

		let selectedSegment = self.dependencySegmentedControl.selectedSegment
		let segmentTag = (self.dependencySegmentedControl.cell as! NSSegmentedCell).tagForSegment(selectedSegment)

		if let svdFile = self.svdFile {
			if segmentTag == 1 {
				filteredLiveSets = svdFile.liveSets
			} else if segmentTag == 2 {
				for svdLive in svdFile.liveSets {
					if svdLive.registrations.count > 0 {
						filteredLiveSets.append(svdLive)
					}
				}
			} else if segmentTag == 3 {
				for svdLive in svdFile.liveSets {
					if svdLive.registrations.count <= 0 {
						filteredLiveSets.append(svdLive)
					}
				}
			} else {
				return
			}
		}

		self.updateTableFromList(filteredLiveSets)
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

	// MARK: Table view

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == self.livesTableView {
			nrOfRows = self.tableData.count
		} else if tableView == self.regsTableView {
			nrOfRows = self.regsTableData.count
		}

		return nrOfRows
	}

	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let result = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner:self) as! NSTableCellView

		result.textField?.textColor = NSColor.blackColor()

		var columnValue: String = ""
		var textColor = NSColor.blackColor()

		let svdLive = self.tableData[row]

		if tableView == self.livesTableView {
			if tableColumn == self.nameColumn {
				columnValue = svdLive.liveName
				textColor = self.textColorForLiveSetName(columnValue)
			} else if tableColumn == self.orderColumn {
				columnValue = "\(svdLive.orderNr)"
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

				columnValue = layerName!

				if layerTone != nil {
					textColor = self.textColorForToneName(columnValue)
				} else if layerName != nil {
					textColor = self.textColorForPartType(layerToneType)
				}
			}
		} else if tableView == self.regsTableView {
			if tableColumn == self.regNameColumn {
				columnValue = self.regsTableData[row].regName
			} else if tableColumn == self.regOrderColumn {
				columnValue = "\(self.regsTableData[row].orderNr)"
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [AnyObject]) {
		if tableView == self.regsTableView {
			self.regsTableData = (self.regsTableData as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as! [SVDRegistration]
		} else {
			self.tableData = (self.tableData as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as! [SVDLiveSet]
		}

		tableView.reloadData()
	}

	func tableViewSelectionDidChange(aNotification: NSNotification) {
		let tableView = aNotification.object as! NSTableView

		if tableView == self.livesTableView {
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

							for svdLive in self.tableData {
								var name: String

								if textField == self.nameTextField {
									name = svdLive.liveName
								} else if textField == self.layer1TextField {
									name = svdLive.layer1Name
								} else if textField == self.layer2TextField {
									name = svdLive.layer2Name
								} else if textField == self.layer3TextField {
									name = svdLive.layer3Name
								} else if textField == self.layer4TextField {
									name = svdLive.layer4Name
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
						self.livesTableView.selectRowIndexes(indexSet, byExtendingSelection: false)

						// Scroll to the first matched row
						if let index = indices.first {
							let rect = self.livesTableView.rectOfRow(index)
							self.livesTableView.scrollPoint(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
						}
					}
				}
			}
		}
	}

	// MARK: Actions

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
