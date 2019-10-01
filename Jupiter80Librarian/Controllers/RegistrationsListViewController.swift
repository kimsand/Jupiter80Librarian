//
//  RegistrationsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class RegistrationsListViewController: SuperListViewController, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var upperColumn: NSTableColumn!
	@IBOutlet var lowerColumn: NSTableColumn!
	@IBOutlet var soloColumn: NSTableColumn!
	@IBOutlet var percColumn: NSTableColumn!

	// MARK: Lifecycle

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		svdSubType = .registration
	}

    override func viewDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(RegistrationsListViewController.svdFileDidUpdate(_:)), name: NSNotification.Name(rawValue: "svdFileDidUpdate"), object: nil)
        super.viewDidLoad()

		updateSVD()
	}

	// MARK: Member methods

	private func buildSelectionList() {
		let selectedRowIndexes = listTableView.selectedRowIndexes
		var selectedRegs: [SVDRegistration] = []

		for index in selectedRowIndexes {
			let svdReg = tableData[index] as! SVDRegistration
			selectedRegs.append(svdReg)
		}

		var unselectedRegs: [SVDRegistration] = []

		for registration in model.selectedRegistrations {
			if selectedRegs.firstIndex(of: registration) == nil
				&& tableData.firstIndex(of: registration) != nil {
					unselectedRegs.append(registration)
			}
		}

		// Add rows that are newly selected
		for registration in selectedRegs {
			if unselectedRegs.firstIndex(of: registration) == nil {
				if model.selectedRegistrations.firstIndex(of: registration) == nil {
					model.selectedRegistrations.append(registration)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedRegs {
			let foundIndex = model.selectedRegistrations.firstIndex(of: liveSet)

			if foundIndex != nil {
				model.selectedRegistrations.remove(at: foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		model.selectedRegistrations = (model.selectedRegistrations as NSArray).sortedArray(using: [sortDesc]) as! [SVDRegistration]
	}

	// MARK: Table view

    @objc func numberOfRows(in tableView: NSTableView) -> Int {
		let nrOfRows = tableData.count

		return nrOfRows
	}

    @objc func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		let result = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView
		result.textField?.textColor = .labelColor

		let svdReg = tableData[row] as! SVDRegistration
		var columnValue: String = ""
		var textColor = NSColor.labelColor

		if tableColumn == nameColumn {
			columnValue = svdReg.regName
			setInitStatusForRegistrationName(columnValue)
			textColor = textColorForRegistrationName(columnValue)
		} else if tableColumn == orderColumn {
			columnValue = "\(svdReg.orderNr)"
		} else if tableColumn == upperColumn {
			columnValue = svdReg.upperName as String
			textColor = textColorForLiveSetName(columnValue)
		} else if tableColumn == lowerColumn {
			if svdFile != nil {
				if svdFile!.fileFormat == .jupiter80 {
					columnValue = svdReg.lowerName as String
					textColor = textColorForLiveSetName(columnValue)
				} else {
					columnValue = "NOT USED"
					textColor = .secondaryLabelColor
				}
			}
		} else if tableColumn == soloColumn {
			columnValue = svdReg.soloName

			if svdReg.soloTone != nil {
				textColor = textColorForToneName(columnValue)
			} else {
				textColor = textColorForPartType(svdReg.soloToneType!)
			}
		} else if tableColumn == percColumn {
			columnValue = svdReg.percName

			if svdReg.percTone != nil {
				textColor = textColorForToneName(columnValue)
			} else {
				textColor = textColorForPartType(svdReg.percToneType!)
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		tableData = (tableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDRegistration]
		tableView.reloadData()
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		let tableView = notification.object as! NSTableView

		if tableView == listTableView {
			buildSelectionList()
		}
	}
}
