//
//  LiveSetsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//

import Cocoa

class LiveSetsListViewController: SuperListViewController, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var layer1Column: NSTableColumn!
	@IBOutlet var layer2Column: NSTableColumn!
	@IBOutlet var layer3Column: NSTableColumn!
	@IBOutlet var layer4Column: NSTableColumn!

	@IBOutlet var regsTableView: NSTableView!
	@IBOutlet var regNameColumn: NSTableColumn!
	@IBOutlet var regOrderColumn: NSTableColumn!

	private var regsTableData: [SVDRegistration] = []

	// MARK: - Lifecycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        svdSubType = .liveSet
    }

	override func viewDidLoad() {
		super.viewDidLoad()

        deactivateBreakingLayoutConstraint()
	}

	// MARK: - Member methods

	private func buildSelectionList() {
        guard let model = model else { return }

        let selectedRowIndexes = listTableView.selectedRowIndexes
		var selectedLiveSets: [SVDLiveSet] = []

		for index in selectedRowIndexes {
            if let svdLive = tableData[index] as? SVDLiveSet {
                selectedLiveSets.append(svdLive)
            }
		}

		var unselectedLiveSets: [SVDLiveSet] = []

		for liveSet in model.selectedLiveSets {
			if selectedLiveSets.firstIndex(of: liveSet) == nil
				&& tableData.firstIndex(of: liveSet) != nil {
					unselectedLiveSets.append(liveSet)
			}
		}

		// Add rows that are newly selected
		for liveSet in selectedLiveSets {
			if unselectedLiveSets.firstIndex(of: liveSet) == nil {
				if model.selectedLiveSets.firstIndex(of: liveSet) == nil {
					model.selectedLiveSets.append(liveSet)
				}
			}
		}

		// Remove rows that are newly unselected
		for liveSet in unselectedLiveSets {
            if let foundIndex = model.selectedLiveSets.firstIndex(of: liveSet) {
                model.selectedLiveSets.remove(at: foundIndex)
            }
		}

		// Sort the array by orderNr when done updating
		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)
		model.selectedLiveSets = (model.selectedLiveSets as NSArray).sortedArray(using: [sortDesc]) as! [SVDLiveSet]
	}

	// MARK: - Table view

    @objc func numberOfRows(in tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if tableView == listTableView {
			nrOfRows = tableData.count
		} else if tableView == regsTableView {
			nrOfRows = regsTableData.count
		}

		return nrOfRows
	}

    @objc func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let result = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView

		result.textField?.textColor = .labelColor

		var columnValue: String = ""
		var textColor = NSColor.labelColor

        if tableView == regsTableView {
            if tableColumn == regNameColumn {
                columnValue = regsTableData[row].regName
            } else if tableColumn == regOrderColumn {
                columnValue = "\(regsTableData[row].orderNr)"
            }
        } else if tableView == listTableView {
			let svdLive = tableData[row] as! SVDLiveSet

			if tableColumn == nameColumn {
				columnValue = svdLive.liveName
				setInitStatusForLiveSetName(columnValue)
				textColor = textColorForLiveSetName(columnValue)
			} else if tableColumn == orderColumn {
				columnValue = "\(svdLive.orderNr)"
			} else if tableColumn == layer1Column
				|| tableColumn == layer2Column
				|| tableColumn == layer3Column
				|| tableColumn == layer4Column
			{
				var layerNr: Int

				if tableColumn == layer1Column {
					layerNr = 0
				} else if tableColumn == layer2Column {
					layerNr = 1
				} else if tableColumn == layer3Column {
					layerNr = 2
				} else {
					layerNr = 3
				}

				let layerToneType = svdLive.layerToneTypes[layerNr]
				let layerTone = svdLive.layerTones[layerNr]
				let layerName = svdLive.layerNames[layerNr]

				columnValue = layerName!

				if layerTone != nil {
					textColor = textColorForToneName(columnValue)
				} else if layerName != nil {
					textColor = textColorForPartType(layerToneType)
				}
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
	}

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		if tableView == regsTableView {
			regsTableData = (regsTableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDRegistration]
		} else {
			tableData = (tableData as NSArray).sortedArray(using: tableView.sortDescriptors) as! [SVDLiveSet]
		}

		tableView.reloadData()
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		let tableView = notification.object as! NSTableView

		if tableView == listTableView {
			buildSelectionList()
			buildDependencyList(&regsTableData)
			regsTableView.reloadData()
		}
	}
}
