//
//  TonesListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class TonesListViewController: SuperListViewController {
	@IBOutlet var partial1TextField: NSTextField!
	@IBOutlet var partial2TextField: NSTextField!
	@IBOutlet var partial3TextField: NSTextField!

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

	var livesTableData: [SVDLiveSet] = []
	var regsTableData: [SVDRegistration] = []

	// MARK: Lifecycle

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.svdSubType = .Tone
	}

	override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TonesListViewController.svdFileDidUpdate(_:)), name: "svdFileDidUpdate", object: nil)
		super.viewDidLoad()

		self.updateSVD()
	}

	// MARK: Member methods

	func buildSelectionList() {
		let selectedRowIndexes = self.listTableView.selectedRowIndexes
		var selectedTones: [SVDTone] = []

		for index in selectedRowIndexes {
			let svdTone = self.tableData[index] as! SVDTone
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

	// MARK: Table view

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == self.listTableView {
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

		if tableView == self.listTableView {
			let svdTone = self.tableData[row] as! SVDTone

			if tableColumn == self.nameColumn {
				columnValue = svdTone.toneName
				self.setInitStatusForToneName(columnValue)
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

		if tableView == self.listTableView {
			self.buildSelectionList()
			let includeRegsFromLiveSets = self.livesRegsCheckButton.state == NSOnState
			self.buildDependencyList(&self.regsTableData, livesTableData: &self.livesTableData, includeRegsFromLiveSets: includeRegsFromLiveSets)
			self.regsTableView.reloadData()
			self.livesTableView.reloadData()
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

									index += 1
								}
							}

							// Scroll to the first matched row
							if let index = indices.first {
								let rect = self.listTableView.rectOfRow(index)
								self.listTableView.scrollPoint(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
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

							for svdTone in self.tableData as! [SVDTone] {
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

								index += 1
							}

							// If any rows were matched
							if indices.count > 0 {
								var filteredTones: [SVDTone] = []

								for index in indices {
									let tone = self.tableData[index] as! SVDTone
									filteredTones.append(tone)
								}

								self.updateTableFromList(filteredTones)
							}
						} else {
							if let allTones = svdFile?.tones {
								self.updateTableFromList(allTones)
							}
						}
					}
				}
			}
		}
	}

	// MARK: Actions

	@IBAction func liveRegsCheckButtonClicked(sender: NSButton) {
		let includeRegsFromLiveSets = self.livesRegsCheckButton.state == NSOnState
		self.buildDependencyList(&self.regsTableData, livesTableData: &self.livesTableData, includeRegsFromLiveSets: includeRegsFromLiveSets)
		self.regsTableView.reloadData()
		self.livesTableView.reloadData()
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
