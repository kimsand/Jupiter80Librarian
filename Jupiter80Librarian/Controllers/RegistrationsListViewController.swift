//
//  RegistrationsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class RegistrationsListViewController: SuperListViewController {
	@IBOutlet var upperColumn: NSTableColumn!
	@IBOutlet var lowerColumn: NSTableColumn!
	@IBOutlet var soloColumn: NSTableColumn!
	@IBOutlet var percColumn: NSTableColumn!

	// MARK: Lifecycle

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.svdSubType = .registration
	}

    override func viewDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(RegistrationsListViewController.svdFileDidUpdate(_:)), name: NSNotification.Name(rawValue: "svdFileDidUpdate"), object: nil)
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
			if selectedRegs.index(of: registration) == nil
				&& self.tableData.index(of: registration) != nil {
					unselectedRegs.append(registration)
			}
		}

		// Add rows that are newly selected
		for registration in selectedRegs {
			if unselectedRegs.index(of: registration) == nil {
				if Model.singleton.selectedRegistrations.index(of: registration) == nil {
					Model.singleton.selectedRegistrations.append(registration)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedRegs {
			let foundIndex = Model.singleton.selectedRegistrations.index(of: liveSet)

			if foundIndex != nil {
				Model.singleton.selectedRegistrations.remove(at: foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		Model.singleton.selectedRegistrations = (Model.singleton.selectedRegistrations as NSArray).sortedArray(using: [sortDesc]) as! [SVDRegistration]
	}

	// MARK: Table view

	func numberOfRowsInTableView(_ tableView: NSTableView) -> Int {
		let nrOfRows = self.tableData.count

		return nrOfRows
	}

	func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		let result = tableView.make(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView
		result.textField?.textColor = NSColor.black

		let svdReg = self.tableData[row] as! SVDRegistration
		var columnValue: String = ""
		var textColor = NSColor.black

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
				if self.svdFile!.fileFormat == .jupiter80 {
					columnValue = svdReg.lowerName as String
					textColor = self.textColorForLiveSetName(columnValue)
				} else {
					columnValue = "NOT USED"
					textColor = NSColor.lightGray
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

	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		self.tableData = (self.tableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDRegistration]
		tableView.reloadData()
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		let tableView = notification.object as! NSTableView

		if tableView == self.listTableView {
			self.buildSelectionList()
		}
	}
}
