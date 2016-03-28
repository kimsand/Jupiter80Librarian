//
//  RegistrationsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class RegistrationsListViewController: SuperListViewController {
	@IBOutlet var upperTextField: NSTextField!
	@IBOutlet var lowerTextField: NSTextField!
	@IBOutlet var soloTextField: NSTextField!
	@IBOutlet var percTextField: NSTextField!

	@IBOutlet var upperColumn: NSTableColumn!
	@IBOutlet var lowerColumn: NSTableColumn!
	@IBOutlet var soloColumn: NSTableColumn!
	@IBOutlet var percColumn: NSTableColumn!

	// MARK: Lifecycle

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.svdSubType = .Registration
	}

    override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RegistrationsListViewController.svdFileDidUpdate(_:)), name: "svdFileDidUpdate", object: nil)
        super.viewDidLoad()

		self.updateSVD()
	}

	// MARK: Member methods

	func buildSelectionList() {
		let selectedRowIndexes = self.listTableView.selectedRowIndexes
		var selectedRegs: [SVDRegistration] = []

		for index in selectedRowIndexes {
			let svdReg = self.tableData[index] as! SVDRegistration
			selectedRegs.append(svdReg)
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

		let svdReg = self.tableData[row] as! SVDRegistration
		var columnValue: String = ""
		var textColor = NSColor.blackColor()

		if tableColumn == self.nameColumn {
			columnValue = svdReg.regName
			self.setInitStatusForRegistrationName(columnValue)
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

		if tableView == self.listTableView {
			self.buildSelectionList()
		}
	}

	// MARK: Text field

	override func controlTextDidEndEditing(obj: NSNotification) {
		if let textMovement = obj.userInfo?["NSTextMovement"] as? Int {
			// Only process the text field when the Return key was pressed
			if textMovement == NSReturnTextMovement {
				if let textField = obj.object as? NSTextField {
					// The order field matches one and only one row number
					if textField == self.orderTextField {
						// Only process the text field when text was entered
						if let orderNr = Int(textField.stringValue) {
							scrollToOrderNr(orderNr)
						}
					} else if self.tableData.count > 0 {
						// Only process the text field when text was entered
						if textField.stringValue.characters.count > 0 {
							var nameIndices: [(String, Int)] = []
							var index = 0

							for svdReg in self.tableData as! [SVDRegistration] {
								var name: String?

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

								if name != nil {
									nameIndices.append((name!, index))
								}
								
								index += 1
							}

							let text = textField.stringValue.lowercaseString

							filterListOnNameIndices(nameIndices, text: text)
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

}
