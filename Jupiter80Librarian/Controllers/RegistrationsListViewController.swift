//
//  RegistrationsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class RegistrationsListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	enum DependencySegment: Int {
		case All = 1
		case Selected
	}

	@IBOutlet var orderTextField: NSTextField!
	@IBOutlet var nameTextField: NSTextField!
	@IBOutlet var upperTextField: NSTextField!
	@IBOutlet var lowerTextField: NSTextField!
	@IBOutlet var soloTextField: NSTextField!
	@IBOutlet var percTextField: NSTextField!

	@IBOutlet var regsTableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var upperColumn: NSTableColumn!
	@IBOutlet var lowerColumn: NSTableColumn!
	@IBOutlet var soloColumn: NSTableColumn!
	@IBOutlet var percColumn: NSTableColumn!

	@IBOutlet var dependencySegmentedControl: NSSegmentedControl!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var lastValidOrderText = ""

	var tableData: [SVDRegistration] = []

	// MARK: Lifecycle

    override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
        super.viewDidLoad()

		self.updateSVD()
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		NSApplication.sharedApplication().mainWindow?.makeFirstResponder(self.regsTableView)
	}

	// MARK: Member methods

	func updateSVD() {
		self.svdFile = self.model.openedSVDFile
		self.tableData.removeAll(keepCapacity: true)

		if let svdFile = self.svdFile {
			self.tableData += svdFile.registrations
		}

		self.regsTableView.reloadData()
	}

	func indexSetFromRegistrations(registrations: [SVDRegistration]) -> NSIndexSet {
		let indexSet = NSMutableIndexSet()

		// Keep selection when updating the list view
		for liveSet in Model.singleton.selectedRegistrations {
			let index = self.tableData.indexOf(liveSet)

			if index != nil {
				indexSet.addIndex(index!)
			}
		}

		return indexSet
	}

	func updateTableFromList(registrations: [SVDRegistration]) {
		self.tableData.removeAll(keepCapacity: true)
		self.tableData += registrations
		self.regsTableView.reloadData()

		let indexSet = self.indexSetFromRegistrations(registrations)
		self.regsTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
	}

	func buildSelectionList() {
		let selectedRowIndexes = self.regsTableView.selectedRowIndexes
		var selectedRegs: [SVDRegistration] = []

		for index in selectedRowIndexes {
			let svdLive = self.tableData[index]
			selectedRegs.append(svdLive)
		}

		var unselectedRegs: [SVDRegistration] = []

		for registration in Model.singleton.selectedRegistrations {
			if selectedRegs.indexOf(registration) == nil
				&& self.tableData.indexOf(registration) != nil {
					unselectedRegs.append(registration)
			}
		}

		// Add rows that are newly selected
		for registration in selectedRegs {
			if unselectedRegs.indexOf(registration) == nil {
				if Model.singleton.selectedRegistrations.indexOf(registration) == nil {
					Model.singleton.selectedRegistrations.append(registration)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedRegs {
			let foundIndex = Model.singleton.selectedRegistrations.indexOf(liveSet)

			if foundIndex != nil {
				Model.singleton.selectedRegistrations.removeAtIndex(foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		Model.singleton.selectedRegistrations = (Model.singleton.selectedRegistrations as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDRegistration]
	}

	func filterDependencies() {
		var filteredRegs: [SVDRegistration] = []

		let selectedSegment = self.dependencySegmentedControl.selectedSegment
		let segmentTag = (self.dependencySegmentedControl.cell as! NSSegmentedCell).tagForSegment(selectedSegment)

		if let svdFile = self.svdFile {
			switch segmentTag {
			case DependencySegment.All.rawValue:
				filteredRegs = svdFile.registrations
			case DependencySegment.Selected.rawValue:
				for svdReg in Model.singleton.selectedRegistrations {
					filteredRegs.append(svdReg)
				}
			default:
				return
			}
		}

		self.updateTableFromList(filteredRegs)
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

	// MARK: Table view

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		let nrOfRows = self.tableData.count

		return nrOfRows
	}

	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		let result = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner:self) as! NSTableCellView
		result.textField?.textColor = NSColor.blackColor()

		let svdReg = self.tableData[row]
		var columnValue: String = ""
		var textColor = NSColor.blackColor()

		if tableColumn == self.nameColumn {
			columnValue = svdReg.regName
			textColor = self.textColorForRegistrationName(columnValue)
		} else if tableColumn == self.orderColumn {
			columnValue = "\(svdReg.orderNr)"
		} else if tableColumn == self.upperColumn {
			columnValue = svdReg.upperName as String
			textColor = self.textColorForLiveSetName(columnValue)
		} else if tableColumn == self.lowerColumn {
			if self.svdFile != nil {
				if self.svdFile!.fileFormat == .Jupiter80 {
					columnValue = svdReg.lowerName as String
					textColor = self.textColorForLiveSetName(columnValue)
				} else {
					columnValue = "NOT USED"
					textColor = NSColor.lightGrayColor()
				}
			}
		} else if tableColumn == self.soloColumn {
			columnValue = svdReg.soloName

			if svdReg.soloTone != nil {
				textColor = self.textColorForToneName(columnValue)
			} else {
				textColor = self.textColorForPartType(svdReg.soloToneType!)
			}
		} else if tableColumn == self.percColumn {
			columnValue = svdReg.percName

			if svdReg.percTone != nil {
				textColor = self.textColorForToneName(columnValue)
			} else {
				textColor = self.textColorForPartType(svdReg.percToneType!)
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		self.tableData = (self.tableData as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as! [SVDRegistration]
		tableView.reloadData()
	}

	func tableViewSelectionDidChange(notification: NSNotification) {
		let tableView = notification.object as! NSTableView

		if tableView == self.regsTableView {
			self.buildSelectionList()
		}
	}

	// MARK: Text field

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

							// Scroll to the first matched row
							if let index = indices.first {
								let rect = self.regsTableView.rectOfRow(index)
								self.regsTableView.scrollPoint(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
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

							for svdReg in self.tableData {
								var name: String

								if textField == self.nameTextField {
									name = svdReg.regName
								} else if textField == self.upperTextField {
									name = svdReg.upperName
								} else if textField == self.lowerTextField {
									name = svdReg.lowerName
								} else if textField == self.soloTextField {
									name = svdReg.soloName
								} else if textField == self.percTextField {
									name = svdReg.percName
								} else {
									break // unsupported field
								}

								if name.lowercaseString.hasPrefix(text) {
									indices.append(index)
								}

								index++
							}

							// If any rows were matched
							if indices.count > 0 {
								var filteredRegs: [SVDRegistration] = []

								for index in indices {
									let reg = self.tableData[index]
									filteredRegs.append(reg)
								}

								self.updateTableFromList(filteredRegs)
							}
						} else {
							if let allRegs = svdFile?.registrations {
								self.updateTableFromList(allRegs)
							}
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
