//
//  SuperListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 06/03/16.
//  Copyright © 2016 Kim André Sand. All rights reserved.
//

import Cocoa

class SuperListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	enum DependencySegment: Int {
		case all = 1
		case selected
		case used
		case unused
	}

	@IBOutlet var orderTextField: NSTextField!
	@IBOutlet var nameSearchField: NSSearchField!
	@IBOutlet var layer1SearchField: NSSearchField?
	@IBOutlet var layer2SearchField: NSSearchField?
	@IBOutlet var layer3SearchField: NSSearchField?
	@IBOutlet var layer4SearchField: NSSearchField?

	@IBOutlet var listTableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!

	@IBOutlet var dependencySegmentedControl: NSSegmentedControl!
    @IBOutlet var breakingLayoutConstraint: NSLayoutConstraint!

    let model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var lastValidOrderText = ""

	var svdSubType: SVDSubType
	var tableData: [SVDType] = []

    var wasLastCommandDeleteKey = false

	// MARK: - Lifecycle

	required init?(coder: NSCoder) {
		// Set a dummy value to satisfy compiler. The actual value is set by the sub class.
		svdSubType = .registration
		super.init(coder: coder)
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		NSApplication.shared.mainWindow?.makeFirstResponder(listTableView)
	}

    func deactivateBreakingLayoutConstraint() {
        NSLayoutConstraint.deactivate([breakingLayoutConstraint])
    }

    func activateBreakingLayoutConstraint() {
        NSLayoutConstraint.activate([breakingLayoutConstraint])
    }

    // MARK: - Member methods

	func updateSVD() {
		svdFile = model.openedSVDFile

		if let svdFile = svdFile {
			tableData.removeAll(keepingCapacity: true)

			switch svdSubType {
			case .registration:
				tableData += svdFile.registrations as [SVDType]
			case .liveSet:
				tableData += svdFile.liveSets as [SVDType]
			case .tone:
				tableData += svdFile.tones as [SVDType]
			}
		}

		listTableView.reloadData()
	}

	private func indexSetFromTypes() -> IndexSet {
		let indexSet = NSMutableIndexSet()

		let selectedTypes: [SVDType]

		switch svdSubType {
		case .registration:
			selectedTypes = model.selectedRegistrations as [SVDType]
		case .liveSet:
			selectedTypes = model.selectedLiveSets as [SVDType]
		case .tone:
			selectedTypes = model.selectedTones as [SVDType]
		}

		// Keep selection when updating the list view
		for selectedType in selectedTypes {
			let index = tableData.firstIndex(of: selectedType)

			if index != nil {
				indexSet.add(index!)
			}
		}

		return indexSet as IndexSet
	}

	private func updateTableFromTypeList(_ svdTypes: [SVDType]) {
		tableData.removeAll(keepingCapacity: true)
		tableData += svdTypes

		// Sort according to the selected table view sort descriptors
		tableData = (tableData as NSArray).sortedArray(using: listTableView.sortDescriptors) as! [SVDType]

		listTableView.reloadData()

		let indexSet = indexSetFromTypes()
		listTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
	}

    private func filterTable() {
        // Reset to the list filtered by the dependency segment
        var filteredTypes = typeListFilteredOnDependencies()

        // Filter based on the content of ALL filter text fields
        filteredTypes = typeListFilteredOnTextFieldsForTypeList(filteredTypes)
        resetTextFieldFiltersFromTypeList(filteredTypes)

        updateTableFromTypeList(filteredTypes)
    }

	// MARK: - Dependency management

	func buildDependencyList(_ regsTableData: inout [SVDRegistration]) {
		var livesTableData = [SVDLiveSet]()
		buildDependencyList(&regsTableData, livesTableData: &livesTableData)
	}

	func buildDependencyList(_ regsTableData: inout [SVDRegistration], livesTableData: inout [SVDLiveSet], includeRegsFromLiveSets: Bool = false) {
		let selectedRowIndexes = indexSetFromTypes()
		let regSet = NSMutableSet(capacity: selectedRowIndexes.count)
		let liveSet = NSMutableSet(capacity: selectedRowIndexes.count)

		(selectedRowIndexes as NSIndexSet).enumerate({
			(index: Int, finished: UnsafeMutablePointer<ObjCBool>) -> Void in
			
			switch svdSubType {
			case .liveSet:
				let svdLive = tableData[index] as! SVDLiveSet
				
				regSet.addObjects(from: svdLive.registrations)
			case .tone:
				let svdTone = tableData[index] as! SVDTone
				
				regSet.addObjects(from: svdTone.registrations)
				liveSet.addObjects(from: svdTone.liveSets)
				
				// If selected, also add registrations from live sets using the tone
				if includeRegsFromLiveSets {
					for live in svdTone.liveSets {
						regSet.addObjects(from: live.registrations)
					}
				}
			default:
				break
			}
		})

		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)

		let regList = (regSet.allObjects as NSArray).sortedArray(using: [sortDesc]) as! [SVDRegistration]
		let liveList = (liveSet.allObjects as NSArray).sortedArray(using: [sortDesc]) as! [SVDLiveSet]

		regsTableData.removeAll(keepingCapacity: true)
		regsTableData += regList

		livesTableData.removeAll(keepingCapacity: true)
		livesTableData += liveList
	}

	private func typeListFilteredOnDependencies(ignoreSearchFilter doIgnoreSearchFilter: Bool = true) -> [SVDType] {
		var filteredTypes: [SVDType] = []

		guard let svdFile = svdFile else {
			return filteredTypes
		}

		let selectedSegment = dependencySegmentedControl.selectedSegment
		let segmentTag = (dependencySegmentedControl.cell as! NSSegmentedCell).tag(forSegment: selectedSegment)

		let searchFilteredTypes: [SVDType]
		let selectedTypes: [SVDType]
		let svdFileTypes: [SVDType]

		switch svdSubType {
		case .registration:
			svdFileTypes = svdFile.registrations as [SVDType]
			selectedTypes = model.selectedRegistrations as [SVDType]
			if !doIgnoreSearchFilter {
				searchFilteredTypes = model.filteredRegistrations as [SVDType]
			} else {
				searchFilteredTypes = []
			}
		case .liveSet:
			svdFileTypes = svdFile.liveSets as [SVDType]
			selectedTypes = model.selectedLiveSets as [SVDType]
			if !doIgnoreSearchFilter {
				searchFilteredTypes = model.filteredLiveSets as [SVDType]
			} else {
				searchFilteredTypes = []
			}
		case .tone:
			svdFileTypes = svdFile.tones as [SVDType]
			selectedTypes = model.selectedTones as [SVDType]
			if !doIgnoreSearchFilter {
				searchFilteredTypes = model.filteredTones as [SVDType]
			} else {
				searchFilteredTypes = []
			}
		}

		switch segmentTag {
		case DependencySegment.all.rawValue:
			if searchFilteredTypes.count > 0 {
				filteredTypes = searchFilteredTypes
			} else {
				filteredTypes = svdFileTypes
			}
		case DependencySegment.selected.rawValue:
			var listOfTypes: [SVDType]

			if searchFilteredTypes.count > 0 {
				listOfTypes = [SVDType]()
				for svdType in searchFilteredTypes {
					if selectedTypes.contains(svdType) {
						listOfTypes.append(svdType)
					}
				}
			} else {
				listOfTypes = selectedTypes
			}

			for svdType in listOfTypes {
				filteredTypes.append(svdType)
			}
		case DependencySegment.used.rawValue:
			var listOfTypes: [SVDType]

			if searchFilteredTypes.count > 0 {
				listOfTypes = searchFilteredTypes
			} else {
				listOfTypes = svdFileTypes
			}

			for svdType in listOfTypes {
				switch svdSubType {
				case .registration:
					break
				case .liveSet:
					if let svdLive = svdType as? SVDLiveSet {
						if svdLive.registrations.count > 0 {
							filteredTypes.append(svdType)
						}
					}
				case .tone:
					if let svdTone = svdType as? SVDTone {
						if svdTone.liveSets.count > 0
							|| svdTone.registrations.count > 0 {
							filteredTypes.append(svdType)
						}
					}
				}
			}
		case DependencySegment.unused.rawValue:
			var listOfTypes: [SVDType]

			if searchFilteredTypes.count > 0 {
				listOfTypes = searchFilteredTypes
			} else {
				listOfTypes = svdFileTypes
			}

			for svdType in listOfTypes {
				switch svdSubType {
				case .registration:
					break
				case .liveSet:
					if let svdLive = svdType as? SVDLiveSet {
						if svdLive.registrations.count <= 0 {
							filteredTypes.append(svdType)
						}
					}
				case .tone:
					if let svdTone = svdType as? SVDTone {
						if svdTone.liveSets.count <= 0
							&& svdTone.registrations.count <= 0 {
							filteredTypes.append(svdType)
						}
					}
				}
			}
		default:
			return filteredTypes
		}

		return filteredTypes
	}

	// MARK: - Text colors based on sound type and sound name

	func textColorForRegistrationName(_ regName: String) -> NSColor {
		var textColor = NSColor.labelColor

		if isInitSound == true || regName == "INIT REGIST" {
			textColor = .secondaryLabelColor
		}

		return textColor
	}

	func textColorForLiveSetName(_ liveName: String) -> NSColor {
		var textColor = NSColor.labelColor

		if isInitSound == true || liveName == "INIT LIVESET" {
			textColor = .secondaryLabelColor
		}

		return textColor
	}

	func textColorForToneName(_ toneName: String) -> NSColor {
		var textColor = NSColor.labelColor

		if isInitSound == true || toneName == "INIT SYNTH" {
			textColor = .secondaryLabelColor
		}

		return textColor
	}

	func textColorForPartType(_ partType: SVDPartType) -> NSColor {
		var textColor = NSColor.labelColor

		if isInitSound == true {
			textColor = .secondaryLabelColor
		} else if partType.mainType == .acoustic {
			textColor = .systemPurple
		} else if partType.mainType == .drumSet {
			textColor = .systemBlue
		}

		return textColor
	}

	func textColorForOscType(_ oscType: SVDOscType) -> NSColor {
		var textColor = NSColor.labelColor

		if isInitSound == true {
			textColor = .secondaryLabelColor
		} else if oscType == .pcm {
			textColor = .systemPurple
		} else {
			textColor = .systemBlue
		}

		return textColor
	}

	func setInitStatusForRegistrationName(_ regName: String) {
		isInitSound = false

		if regName == "INIT REGIST" {
			isInitSound = true
		}
	}

	func setInitStatusForLiveSetName(_ liveName: String) {
		isInitSound = false

		if liveName == "INIT LIVESET" {
			isInitSound = true
		}
	}

	func setInitStatusForToneName(_ toneName: String) {
		isInitSound = false

		if toneName == "INIT SYNTH" {
			isInitSound = true
		}
	}

	// MARK: - Text field filtering

	private func scrollToOrderNr(_ orderNr: Int) {
		var index = 0

		for svdType in tableData {
			if svdType.orderNr == orderNr {
				break
			} else {
				index += 1
			}
		}

		// Scroll to the first matched row
		let rect = listTableView.rect(ofRow: index)
		listTableView.scroll(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
	}

	private func filteredListForNameIndices(_ nameIndices: [(String, Int)], text: String, typeList: [SVDType]) -> [SVDType] {
		var filteredTypes: [SVDType] = []

		// Search for each word in the search string separately
		let textParts = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)

		if nameIndices.count > 0 {
			var indices = [Int]()

			for (name, index) in nameIndices {
				let nameText = name.lowercased()
				var doesMatchAllParts = true

				// The name must contain all words in the search string to be a match
				for textPart in textParts {
					if !nameText.contains(textPart) {
						doesMatchAllParts = false
						break
					}
				}

				if doesMatchAllParts {
					indices.append(index)
				}
			}

			// If any rows were matched
			if indices.count > 0 {
				for index in indices {
					let svdType = typeList[index]
					filteredTypes.append(svdType)
				}
			}
		}

		return filteredTypes
	}

	private func typeListFilteredOnTextFieldsForTypeList(_ typeList: [SVDType]) -> [SVDType] {
		var filteredTypes = typeList

		if nameSearchField.stringValue.count > 0 {
			filteredTypes = typeListFilteredOnTextField(nameSearchField, typeList: filteredTypes)
		}

		if let layer1SearchField = layer1SearchField, layer1SearchField.stringValue.count > 0 {
			filteredTypes = typeListFilteredOnTextField(layer1SearchField, typeList: filteredTypes)
		}

		if let layer2SearchField = layer2SearchField, layer2SearchField.stringValue.count > 0 {
			filteredTypes = typeListFilteredOnTextField(layer2SearchField, typeList: filteredTypes)
		}

		if let layer3SearchField = layer3SearchField, layer3SearchField.stringValue.count > 0 {
			filteredTypes = typeListFilteredOnTextField(layer3SearchField, typeList: filteredTypes)
		}

		if let layer4SearchField = layer4SearchField, layer4SearchField.stringValue.count > 0 {
			filteredTypes = typeListFilteredOnTextField(layer4SearchField, typeList: filteredTypes)
		}

		return filteredTypes
	}

	private func typeListFilteredOnTextField(_ textField: NSTextField, typeList: [SVDType]) -> [SVDType] {
		let text = textField.stringValue.lowercased()
		var filteredTypes = typeList

		switch svdSubType {
		case .registration:
			if let regList = typeList as? [SVDRegistration] {
				let nameIndices = nameIndicesForRegistrationTextField(textField, regList: regList)
				filteredTypes = filteredListForNameIndices(nameIndices, text: text, typeList: filteredTypes)
			}
		case .liveSet:
			if let liveList = typeList as? [SVDLiveSet] {
				let nameIndices = nameIndicesForLiveSetTextField(textField, liveList: liveList)
				filteredTypes = filteredListForNameIndices(nameIndices, text: text, typeList: filteredTypes)
			}
		case .tone:
			if let toneList = filteredTypes as? [SVDTone] {
				let nameIndices = nameIndicesForToneTextField(textField, toneList: toneList)
				filteredTypes = filteredListForNameIndices(nameIndices, text: text, typeList: filteredTypes)
			}
		}

		return filteredTypes
	}

	private func resetTextFieldFiltersFromTypeList(_ typeList: [SVDType]) {
		switch svdSubType {
		case .registration:
			if let filteredRegs = typeList as? [SVDRegistration] {
				model.filteredRegistrations = filteredRegs
			} else {
				model.filteredRegistrations = [SVDRegistration]()
			}
		case .liveSet:
			if let filteredLives = typeList as? [SVDLiveSet] {
				model.filteredLiveSets = filteredLives
			} else {
				model.filteredLiveSets = [SVDLiveSet]()
			}
		case .tone:
			if let filteredTones = typeList as? [SVDTone] {
				model.filteredTones = filteredTones
			} else {
				model.filteredTones = [SVDTone]()
			}
		}
	}

	private func nameIndicesForRegistrationTextField(_ textField: NSTextField, regList: [SVDRegistration]) -> [(String, Int)] {
		var nameIndices: [(String, Int)] = []
		var index = 0

		for svdReg in regList {
			if let name = nameForRegistrationTextField(textField, svdReg: svdReg) {
				nameIndices.append((name, index))
			}

			index += 1
		}

		return nameIndices
	}

	private func nameIndicesForLiveSetTextField(_ textField: NSTextField, liveList: [SVDLiveSet]) -> [(String, Int)] {
		var nameIndices: [(String, Int)] = []
		var index = 0

		for svdLive in liveList {
			if let name = nameForLiveSetTextField(textField, svdLive: svdLive) {
				nameIndices.append((name, index))
			}

			index += 1
		}

		return nameIndices
	}

	private func nameIndicesForToneTextField(_ textField: NSTextField, toneList: [SVDTone]) -> [(String, Int)] {
		var nameIndices: [(String, Int)] = []
		var index = 0

		for svdTone in toneList {
			if let name = nameForToneTextField(textField, svdTone: svdTone) {
				nameIndices.append((name, index))
			}

			index += 1
		}

		return nameIndices
	}

	private func nameForRegistrationTextField(_ textField: NSTextField, svdReg: SVDRegistration) -> String? {
		var name: String?

		if textField == nameSearchField {
			name = svdReg.regName
		} else if let layer1SearchField = layer1SearchField, textField == layer1SearchField {
			name = svdReg.upperName
		} else if let layer2SearchField = layer2SearchField, textField == layer2SearchField {
			name = svdReg.lowerName
		} else if let layer3SearchField = layer3SearchField, textField == layer3SearchField {
			name = svdReg.soloName
		} else if let layer4SearchField = layer4SearchField, textField == layer4SearchField {
			name = svdReg.percName
		}

		return name
	}

	private func nameForLiveSetTextField(_ textField: NSTextField, svdLive: SVDLiveSet) -> String? {
		var name: String?

		if textField == nameSearchField {
			name = svdLive.liveName
		} else if let layer1SearchField = layer1SearchField, textField == layer1SearchField {
			name = svdLive.layer1Name
		} else if let layer2SearchField = layer2SearchField, textField == layer2SearchField {
			name = svdLive.layer2Name
		} else if let layer3SearchField = layer3SearchField, textField == layer3SearchField {
			name = svdLive.layer3Name
		} else if let layer4SearchField = layer4SearchField, textField == layer4SearchField {
			name = svdLive.layer4Name
		}

		return name
	}

	private func nameForToneTextField(_ textField: NSTextField, svdTone: SVDTone) -> String? {
		var name: String?

		if textField == nameSearchField {
			name = svdTone.toneName
		} else if let layer1SearchField = layer1SearchField, textField == layer1SearchField {
			name = svdTone.partial1Name
		} else if let layer2SearchField = layer2SearchField, textField == layer2SearchField {
			name = svdTone.partial2Name
		} else if let layer3SearchField = layer3SearchField, textField == layer3SearchField {
			name = svdTone.partial3Name
		}

		return name
	}
}

// MARK: - Text field delegate

extension SuperListViewController: NSControlTextEditingDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSStandardKeyBindingResponding.deleteBackward(_:)) {
            wasLastCommandDeleteKey = true
        }
        return false
    }

    func controlTextDidChange(_ obj: Notification) {
        // Filter the table when the user presses the Clear button on a search field.
        // Since there is no way to detect that the Clear button was pressed, instead
        // ensure that the search field was not cleared by using the delete key.
        if
            let searchField = obj.object as? NSSearchField,
            searchField.stringValue.count == 0,
            wasLastCommandDeleteKey == false {
            filterTable()
        }

        wasLastCommandDeleteKey = false
    }

	func controlTextDidEndEditing(_ obj: Notification) {
		if let textMovement = obj.userInfo?["NSTextMovement"] as? Int {
			if let textField = obj.object as? NSTextField, textField == orderTextField {
				if textMovement == NSReturnTextMovement {
					if let orderNr = Int(textField.stringValue) {
						scrollToOrderNr(orderNr)
					}
				}
			} else if nil != obj.object as? NSSearchField {
                if textMovement == NSReturnTextMovement {
                    filterTable()
                }
			}
		}
	}
}

// MARK: Actions

extension SuperListViewController {
	@IBAction func dependencySegmentedControlAction(_ sender: NSSegmentedControl) {
		let filteredTypes = typeListFilteredOnDependencies(ignoreSearchFilter: false)
		updateTableFromTypeList(filteredTypes)
	}

	// MARK: Notifications

	@objc func svdFileDidUpdate(_ notification: Notification) {
		DispatchQueue.main.async {
            self.updateSVD()
		}
	}
}
