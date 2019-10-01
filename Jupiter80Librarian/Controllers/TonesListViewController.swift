//
//  TonesListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class TonesListViewController: SuperListViewController, NSTableViewDataSource, NSTableViewDelegate {
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

	private var livesTableData: [SVDLiveSet] = []
	private var regsTableData: [SVDRegistration] = []

	// MARK: Lifecycle

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		svdSubType = .tone
	}

	override func viewDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(TonesListViewController.svdFileDidUpdate(_:)), name: NSNotification.Name(rawValue: "svdFileDidUpdate"), object: nil)
		super.viewDidLoad()

        deactivateBreakingLayoutConstraint()
		updateSVD()
	}

	// MARK: Member methods

	private func buildSelectionList() {
		let selectedRowIndexes = listTableView.selectedRowIndexes
		var selectedTones: [SVDTone] = []

		for index in selectedRowIndexes {
			let svdTone = tableData[index] as! SVDTone
			selectedTones.append(svdTone)
		}

		var unselectedTones: [SVDTone] = []

		for tone in model.selectedTones {
			if selectedTones.firstIndex(of: tone) == nil
				&& tableData.firstIndex(of: tone) != nil {
					unselectedTones.append(tone)
			}
		}

		// Add rows that are newly selected
		for tone in selectedTones {
			if unselectedTones.firstIndex(of: tone) == nil {
				if model.selectedTones.firstIndex(of: tone) == nil {
					model.selectedTones.append(tone)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedTones {
			let foundIndex = model.selectedTones.firstIndex(of: liveSet)

			if foundIndex != nil {
				model.selectedTones.remove(at: foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		model.selectedTones = (model.selectedTones as NSArray).sortedArray(using: [sortDesc]) as! [SVDTone]
	}

	// MARK: Table view

    @objc func numberOfRows(in tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == listTableView {
			nrOfRows = tableData.count
		} else if tableView == regsTableView {
			nrOfRows = regsTableData.count
		} else if tableView == livesTableView {
			nrOfRows = livesTableData.count
		}

		return nrOfRows
	}

    @objc func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		let result = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView
		result.textField?.textColor = .labelColor

		var columnValue: String = ""
		var textColor = NSColor.labelColor

		if tableView == listTableView {
			let svdTone = tableData[row] as! SVDTone

			if tableColumn == nameColumn {
				columnValue = svdTone.toneName
				setInitStatusForToneName(columnValue)
				textColor = textColorForToneName(columnValue)
			} else if tableColumn == orderColumn {
				columnValue = "\(svdTone.orderNr)"
			} else if tableColumn == partial1Column
				|| tableColumn == partial2Column
				|| tableColumn == partial3Column
			{
				var partialNr: Int

				if tableColumn == partial1Column {
					partialNr = 0
				} else if tableColumn == partial2Column {
					partialNr = 1
				} else {
					partialNr = 2
				}

				columnValue = svdTone.partialNames[partialNr]
				let oscType = svdTone.partialOscTypes[partialNr]
				textColor = textColorForOscType(oscType)
			}
		} else if tableView == regsTableView {
			if tableColumn == regNameColumn {
				columnValue = regsTableData[row].regName
			} else if tableColumn == regOrderColumn {
				columnValue = "\(regsTableData[row].orderNr)"
			}
		} else if tableView == livesTableView {
			if tableColumn == liveNameColumn {
				columnValue = livesTableData[row].liveName
			} else if tableColumn == liveOrderColumn {
				columnValue = "\(livesTableData[row].orderNr)"
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		if tableView == livesTableView {
			livesTableData = (livesTableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDLiveSet]
		} else if tableView == regsTableView {
			regsTableData = (regsTableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDRegistration]
		} else {
			tableData = (tableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDTone]
		}

		tableView.reloadData()
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		let tableView = notification.object as! NSTableView

		if tableView == listTableView {
			buildSelectionList()
			let includeRegsFromLiveSets = livesRegsCheckButton.state == NSControl.StateValue.on
			buildDependencyList(&regsTableData, livesTableData: &livesTableData, includeRegsFromLiveSets: includeRegsFromLiveSets)
			regsTableView.reloadData()
			livesTableView.reloadData()
		}
	}
}

// MARK: - Actions

extension TonesListViewController {
	@IBAction func liveRegsCheckButtonClicked(_ sender: NSButton) {
		let includeRegsFromLiveSets = livesRegsCheckButton.state == NSControl.StateValue.on
		buildDependencyList(&regsTableData, livesTableData: &livesTableData, includeRegsFromLiveSets: includeRegsFromLiveSets)
		regsTableView.reloadData()
		livesTableView.reloadData()
	}
}
