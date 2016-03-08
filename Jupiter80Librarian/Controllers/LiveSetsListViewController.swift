//
//  LiveSetsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class LiveSetsListViewController: SuperListViewController {
	@IBOutlet var layer1TextField: NSTextField!
	@IBOutlet var layer2TextField: NSTextField!
	@IBOutlet var layer3TextField: NSTextField!
	@IBOutlet var layer4TextField: NSTextField!

	@IBOutlet var layer1Column: NSTableColumn!
	@IBOutlet var layer2Column: NSTableColumn!
	@IBOutlet var layer3Column: NSTableColumn!
	@IBOutlet var layer4Column: NSTableColumn!

	@IBOutlet var regsTableView: NSTableView!
	@IBOutlet var regNameColumn: NSTableColumn!
	@IBOutlet var regOrderColumn: NSTableColumn!

	var regsTableData: [SVDRegistration] = []

	// MARK: Lifecycle

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.svdSubType = .LiveSet
	}

	override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
		super.viewDidLoad()

		self.updateSVD()
	}

	// MARK: Member methods

	func buildDependencyList() {
		let selectedRowIndexes = self.indexSetFromTypes()
		let regSet = NSMutableSet(capacity: selectedRowIndexes.count)

		selectedRowIndexes.enumerateIndexesUsingBlock {
			(index: Int, finished: UnsafeMutablePointer<ObjCBool>) -> Void in
			let svdLive = self.tableData[index] as! SVDLiveSet

			regSet.addObjectsFromArray(svdLive.registrations)
		}

		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		let regList = (regSet.allObjects as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDRegistration]

		self.regsTableData.removeAll(keepCapacity: true)
		self.regsTableData += regList

		self.regsTableView.reloadData()
	}

	func buildSelectionList() {
		let selectedRowIndexes = self.listTableView.selectedRowIndexes
		var selectedLiveSets: [SVDLiveSet] = []

		for index in selectedRowIndexes {
			let svdLive = self.tableData[index] as! SVDLiveSet
			selectedLiveSets.append(svdLive)
		}

		var unselectedLiveSets: [SVDLiveSet] = []

		for liveSet in Model.singleton.selectedLiveSets {
			if selectedLiveSets.indexOf(liveSet) == nil
				&& self.tableData.indexOf(liveSet) != nil {
					unselectedLiveSets.append(liveSet)
			}
		}

		// Add rows that are newly selected
		for liveSet in selectedLiveSets {
			if unselectedLiveSets.indexOf(liveSet) == nil {
				if Model.singleton.selectedLiveSets.indexOf(liveSet) == nil {
					Model.singleton.selectedLiveSets.append(liveSet)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedLiveSets {
			let foundIndex = Model.singleton.selectedLiveSets.indexOf(liveSet)

			if foundIndex != nil {
				Model.singleton.selectedLiveSets.removeAtIndex(foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		Model.singleton.selectedLiveSets = (Model.singleton.selectedLiveSets as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDLiveSet]
	}

	func filterDependencies() {
		var filteredLiveSets: [SVDLiveSet] = []

		let selectedSegment = self.dependencySegmentedControl.selectedSegment
		let segmentTag = (self.dependencySegmentedControl.cell as! NSSegmentedCell).tagForSegment(selectedSegment)

		if let svdFile = self.svdFile {
			switch segmentTag {
			case DependencySegment.All.rawValue:
				filteredLiveSets = svdFile.liveSets
			case DependencySegment.Selected.rawValue:
				for svdLive in Model.singleton.selectedLiveSets {
					filteredLiveSets.append(svdLive)
				}
			case DependencySegment.Used.rawValue:
				for svdLive in svdFile.liveSets {
					if svdLive.registrations.count > 0 {
						filteredLiveSets.append(svdLive)
					}
				}
			case DependencySegment.Unused.rawValue:
				for svdLive in svdFile.liveSets {
					if svdLive.registrations.count <= 0 {
						filteredLiveSets.append(svdLive)
					}
				}
			default:
				return
			}
		}

		self.updateTableFromList(filteredLiveSets)
	}

	// MARK: Table view

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == self.listTableView {
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


		if tableView == self.listTableView {
			let svdLive = self.tableData[row] as! SVDLiveSet

			if tableColumn == self.nameColumn {
				columnValue = svdLive.liveName
				self.setInitStatusForLiveSetName(columnValue)
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

	func tableViewSelectionDidChange(notification: NSNotification) {
		let tableView = notification.object as! NSTableView

		if tableView == self.listTableView {
			self.buildSelectionList()
			self.buildDependencyList()
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

							for svdLive in self.tableData as! [SVDLiveSet] {
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

							// If any rows were matched
							if indices.count > 0 {
								var filteredLiveSets: [SVDLiveSet] = []

								for index in indices {
									let liveSet = self.tableData[index] as! SVDLiveSet
									filteredLiveSets.append(liveSet)
								}

								self.updateTableFromList(filteredLiveSets)
							}
						} else {
							if let allLiveSets = svdFile?.liveSets {
								self.updateTableFromList(allLiveSets)
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
