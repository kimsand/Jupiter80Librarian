//
//  LiveSetsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class LiveSetsListViewController: SuperListViewController {
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
		self.svdSubType = .liveSet
	}

	override func viewDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(LiveSetsListViewController.svdFileDidUpdate(_:)), name: NSNotification.Name(rawValue: "svdFileDidUpdate"), object: nil)
		super.viewDidLoad()

		self.updateSVD()
	}

	// MARK: Member methods

	func buildSelectionList() {
		let selectedRowIndexes = self.listTableView.selectedRowIndexes
		var selectedLiveSets: [SVDLiveSet] = []

		for index in selectedRowIndexes {
			let svdLive = self.tableData[index] as! SVDLiveSet
			selectedLiveSets.append(svdLive)
		}

		var unselectedLiveSets: [SVDLiveSet] = []

		for liveSet in Model.singleton.selectedLiveSets {
			if selectedLiveSets.firstIndex(of: liveSet) == nil
				&& self.tableData.firstIndex(of: liveSet) != nil {
					unselectedLiveSets.append(liveSet)
			}
		}

		// Add rows that are newly selected
		for liveSet in selectedLiveSets {
			if unselectedLiveSets.firstIndex(of: liveSet) == nil {
				if Model.singleton.selectedLiveSets.firstIndex(of: liveSet) == nil {
					Model.singleton.selectedLiveSets.append(liveSet)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedLiveSets {
			let foundIndex = Model.singleton.selectedLiveSets.firstIndex(of: liveSet)

			if foundIndex != nil {
				Model.singleton.selectedLiveSets.remove(at: foundIndex!)
			}
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		Model.singleton.selectedLiveSets = (Model.singleton.selectedLiveSets as NSArray).sortedArray(using: [sortDesc]) as! [SVDLiveSet]
	}

	// MARK: Table view

	@objc func numberOfRowsInTableView(_ tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == self.listTableView {
			nrOfRows = self.tableData.count
		} else if tableView == self.regsTableView {
			nrOfRows = self.regsTableData.count
		}

		return nrOfRows
	}

	@objc func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let result = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView

		result.textField?.textColor = .labelColor

		var columnValue: String = ""
		var textColor = NSColor.labelColor


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

	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [AnyObject]) {
		if tableView == self.regsTableView {
			self.regsTableData = (self.regsTableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDRegistration]
		} else {
			self.tableData = (self.tableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDLiveSet]
		}

		tableView.reloadData()
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		let tableView = notification.object as! NSTableView

		if tableView == self.listTableView {
			self.buildSelectionList()
			self.buildDependencyList(&self.regsTableData)
			self.regsTableView.reloadData()
		}
	}

}
 
