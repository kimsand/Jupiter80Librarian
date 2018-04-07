//
//  TonesListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class TonesListViewController: SuperListViewController {
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
		self.svdSubType = .tone
	}

	override func viewDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(TonesListViewController.svdFileDidUpdate(_:)), name: NSNotification.Name(rawValue: "svdFileDidUpdate"), object: nil)
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
			if selectedTones.index(of: tone) == nil
				&& self.tableData.index(of: tone) != nil {
					unselectedTones.append(tone)
			}
		}

		// Add rows that are newly selected
		for tone in selectedTones {
			if unselectedTones.index(of: tone) == nil {
				if Model.singleton.selectedTones.index(of: tone) == nil {
					Model.singleton.selectedTones.append(tone)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedTones {
			let foundIndex = Model.singleton.selectedTones.index(of: liveSet)

			if foundIndex != nil {
				Model.singleton.selectedTones.remove(at: foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		Model.singleton.selectedTones = (Model.singleton.selectedTones as NSArray).sortedArray(using: [sortDesc]) as! [SVDTone]
	}

	// MARK: Table view

	@objc func numberOfRowsInTableView(_ tableView: NSTableView) -> Int {
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

	@objc func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		let result = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView
		result.textField?.textColor = NSColor.black

		var columnValue: String = ""
		var textColor = NSColor.black

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

	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [AnyObject]) {
		if tableView == self.livesTableView {
			self.livesTableData = (self.livesTableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDLiveSet]
		} else if tableView == self.regsTableView {
			self.regsTableData = (self.regsTableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDRegistration]
		} else {
			self.tableData = (self.tableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDTone]
		}

		tableView.reloadData()
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		let tableView = notification.object as! NSTableView

		if tableView == self.listTableView {
			self.buildSelectionList()
			let includeRegsFromLiveSets = self.livesRegsCheckButton.state == NSControl.StateValue.on
			self.buildDependencyList(&self.regsTableData, livesTableData: &self.livesTableData, includeRegsFromLiveSets: includeRegsFromLiveSets)
			self.regsTableView.reloadData()
			self.livesTableView.reloadData()
		}
	}

	// MARK: Actions

	@IBAction func liveRegsCheckButtonClicked(_ sender: NSButton) {
		let includeRegsFromLiveSets = self.livesRegsCheckButton.state == NSControl.StateValue.on
		self.buildDependencyList(&self.regsTableData, livesTableData: &self.livesTableData, includeRegsFromLiveSets: includeRegsFromLiveSets)
		self.regsTableView.reloadData()
		self.livesTableView.reloadData()
	}
}
