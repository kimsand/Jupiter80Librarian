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
		case All = 1
		case Selected
		case Used
		case Unused
	}

	@IBOutlet var orderTextField: NSTextField!
	@IBOutlet var nameTextField: NSTextField!
	@IBOutlet var layer1TextField: NSTextField?
	@IBOutlet var layer2TextField: NSTextField?
	@IBOutlet var layer3TextField: NSTextField?
	@IBOutlet var layer4TextField: NSTextField?

	@IBOutlet var listTableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!

	@IBOutlet var dependencySegmentedControl: NSSegmentedControl!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var lastValidOrderText = ""

	var svdSubType: SVDSubType
	var tableData: [SVDType] = []

	// MARK: Lifecycle

	required init?(coder: NSCoder) {
		// Set a dummy value to satisfy compiler. The actual value is set by the sub class.
		svdSubType = .Registration
		super.init(coder: coder)
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		NSApplication.sharedApplication().mainWindow?.makeFirstResponder(self.listTableView)
	}

	// MARK: Member methods

	func updateSVD() {
		self.svdFile = self.model.openedSVDFile

		if let svdFile = self.svdFile {
			self.tableData.removeAll(keepCapacity: true)

			switch svdSubType {
			case .Registration:
				self.tableData += svdFile.registrations as [SVDType]
			case .LiveSet:
				self.tableData += svdFile.liveSets as [SVDType]
			case .Tone:
				self.tableData += svdFile.tones as [SVDType]
			}
		}

		self.listTableView.reloadData()
	}

	func indexSetFromTypes() -> NSIndexSet {
		let indexSet = NSMutableIndexSet()

		let selectedTypes: [SVDType]
		let tableData: [SVDType]

		switch svdSubType {
		case .Registration:
			selectedTypes = Model.singleton.selectedRegistrations as [SVDType]
			tableData = self.tableData as [SVDType]
		case .LiveSet:
			selectedTypes = Model.singleton.selectedLiveSets as [SVDType]
			tableData = self.tableData as [SVDType]
		case .Tone:
			selectedTypes = Model.singleton.selectedTones as [SVDType]
			tableData = self.tableData as [SVDType]
		}

		// Keep selection when updating the list view
		for selectedType in selectedTypes {
			let index = tableData.indexOf(selectedType)

			if index != nil {
				indexSet.addIndex(index!)
			}
		}

		return indexSet
	}

	func updateTableFromList(svdTypes: [SVDType]) {
		self.tableData.removeAll(keepCapacity: true)
		self.tableData += svdTypes
		self.listTableView.reloadData()

		let indexSet = self.indexSetFromTypes()
		self.listTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
	}

	// MARK: Dependency management

	func buildDependencyList(inout regsTableData: [SVDRegistration]) {
		var livesTableData = [SVDLiveSet]()
		self.buildDependencyList(&regsTableData, livesTableData: &livesTableData)
	}

	func buildDependencyList(inout regsTableData: [SVDRegistration], inout livesTableData: [SVDLiveSet], includeRegsFromLiveSets: Bool = false) {
		let selectedRowIndexes = self.indexSetFromTypes()
		let regSet = NSMutableSet(capacity: selectedRowIndexes.count)
		let liveSet = NSMutableSet(capacity: selectedRowIndexes.count)

		selectedRowIndexes.enumerateIndexesUsingBlock {
			(index: Int, finished: UnsafeMutablePointer<ObjCBool>) -> Void in

			switch self.svdSubType {
			case .LiveSet:
				let svdLive = self.tableData[index] as! SVDLiveSet

				regSet.addObjectsFromArray(svdLive.registrations)
			case .Tone:
				let svdTone = self.tableData[index] as! SVDTone

				regSet.addObjectsFromArray(svdTone.registrations)
				liveSet.addObjectsFromArray(svdTone.liveSets)

				// If selected, also add registrations from live sets using the tone
				if includeRegsFromLiveSets {
					for live in svdTone.liveSets {
						regSet.addObjectsFromArray(live.registrations)
					}
				}
			default:
				break
			}
		}

		let sortDesc = NSSortDescriptor(key: "orderNr", ascending: true)

		let regList = (regSet.allObjects as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDRegistration]
		let liveList = (liveSet.allObjects as NSArray).sortedArrayUsingDescriptors([sortDesc]) as! [SVDLiveSet]

		regsTableData.removeAll(keepCapacity: true)
		regsTableData += regList

		livesTableData.removeAll(keepCapacity: true)
		livesTableData += liveList
	}

	func filterDependencies() {
		guard let svdFile = self.svdFile else {
			return
		}

		let selectedSegment = self.dependencySegmentedControl.selectedSegment
		let segmentTag = (self.dependencySegmentedControl.cell as! NSSegmentedCell).tagForSegment(selectedSegment)

		var filteredTypes: [SVDType] = []
		let searchFilteredTypes: [SVDType]
		let selectedTypes: [SVDType]
		let svdFileTypes: [SVDType]

		switch self.svdSubType {
		case .Registration:
			svdFileTypes = svdFile.registrations as [SVDType]
			selectedTypes = Model.singleton.selectedRegistrations as [SVDType]
			searchFilteredTypes = Model.singleton.filteredRegistrations as [SVDType]
		case .LiveSet:
			svdFileTypes = svdFile.liveSets as [SVDType]
			selectedTypes = Model.singleton.selectedLiveSets as [SVDType]
			searchFilteredTypes = Model.singleton.filteredLiveSets as [SVDType]
		case .Tone:
			svdFileTypes = svdFile.tones as [SVDType]
			selectedTypes = Model.singleton.selectedTones as [SVDType]
			searchFilteredTypes = Model.singleton.filteredTones as [SVDType]
		}

		switch segmentTag {
		case DependencySegment.All.rawValue:
			if searchFilteredTypes.count > 0 {
				filteredTypes = searchFilteredTypes
			} else {
				filteredTypes = svdFileTypes
			}
		case DependencySegment.Selected.rawValue:
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
		case DependencySegment.Used.rawValue:
			var listOfTypes: [SVDType]

			if searchFilteredTypes.count > 0 {
				listOfTypes = searchFilteredTypes
			} else {
				listOfTypes = svdFileTypes
			}

			for svdType in listOfTypes {
				switch self.svdSubType {
				case .Registration:
					break
				case .LiveSet:
					if let svdLive = svdType as? SVDLiveSet {
						if svdLive.registrations.count > 0 {
							filteredTypes.append(svdType)
						}
					}
				case .Tone:
					if let svdTone = svdType as? SVDTone {
						if svdTone.liveSets.count > 0
							|| svdTone.registrations.count > 0 {
							filteredTypes.append(svdType)
						}
					}
				}
			}
		case DependencySegment.Unused.rawValue:
			var listOfTypes: [SVDType]

			if searchFilteredTypes.count > 0 {
				listOfTypes = searchFilteredTypes
			} else {
				listOfTypes = svdFileTypes
			}

			for svdType in listOfTypes {
				switch self.svdSubType {
				case .Registration:
					break
				case .LiveSet:
					if let svdLive = svdType as? SVDLiveSet {
						if svdLive.registrations.count <= 0 {
							filteredTypes.append(svdType)
						}
					}
				case .Tone:
					if let svdTone = svdType as? SVDTone {
						if svdTone.liveSets.count <= 0
							&& svdTone.registrations.count <= 0 {
							filteredTypes.append(svdType)
						}
					}
				}
			}
		default:
			return
		}

		self.updateTableFromList(filteredTypes)
	}

	// MARK: Text colors based on sound type and sound name

	func textColorForRegistrationName(regName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true || regName == "INIT REGIST" {
			textColor = .lightGrayColor()
		}

		return textColor
	}

	func textColorForLiveSetName(liveName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true || liveName == "INIT LIVESET" {
			textColor = .lightGrayColor()
		}

		return textColor
	}

	func textColorForToneName(toneName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true || toneName == "INIT SYNTH" {
			textColor = .lightGrayColor()
		}

		return textColor
	}

	func textColorForPartType(partType: SVDPartType) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true {
			textColor = .lightGrayColor()
		} else if partType.mainType == .Acoustic {
			textColor = .purpleColor()
		} else if partType.mainType == .DrumSet {
			textColor = .blueColor()
		}

		return textColor
	}

	func textColorForOscType(oscType: SVDOscType) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true {
			textColor = .lightGrayColor()
		} else if oscType == .PCM {
			textColor = .purpleColor()
		} else {
			textColor = .blueColor()
		}

		return textColor
	}

	func setInitStatusForRegistrationName(regName: String) {
		self.isInitSound = false

		if regName == "INIT REGIST" {
			self.isInitSound = true
		}
	}

	func setInitStatusForLiveSetName(liveName: String) {
		self.isInitSound = false

		if liveName == "INIT LIVESET" {
			self.isInitSound = true
		}
	}

	func setInitStatusForToneName(toneName: String) {
		self.isInitSound = false

		if toneName == "INIT SYNTH" {
			self.isInitSound = true
		}
	}

	// MARK: Text field filtering

	func scrollToOrderNr(orderNr: Int) {
		var index = 0

		for svdType in self.tableData {
			if svdType.orderNr == orderNr {
				break;
			} else {
				index += 1
			}
		}

		// Scroll to the first matched row
		let rect = self.listTableView.rectOfRow(index)
		self.listTableView.scrollPoint(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
	}

	func filteredListForNameIndices(nameIndices: [(String, Int)], text: String) -> [SVDType] {
		var filteredTypes: [SVDType] = []

		if nameIndices.count > 0 {
			var indices = [Int]()

			for (name, index) in nameIndices {
				if name.lowercaseString.hasPrefix(text) {
					indices.append(index)
				}
			}

			// If any rows were matched
			if indices.count > 0 {
				for index in indices {
					let svdType = self.tableData[index]
					filteredTypes.append(svdType)
				}
			}
		}

		return filteredTypes
	}

	func filterOnTextField(textField: NSTextField) {
		let text = textField.stringValue.lowercaseString
		let filteredTypes: [SVDType]

		switch self.svdSubType {
		case .Registration:
			let nameIndices = self.nameIndicesForRegistrationTextField(textField)
			filteredTypes = filteredListForNameIndices(nameIndices, text: text)

			if let filteredRegs = filteredTypes as? [SVDRegistration] {
				Model.singleton.filteredRegistrations = filteredRegs
			}
		case .LiveSet:
			let nameIndices = self.nameIndicesForLiveSetTextField(textField)
			filteredTypes = filteredListForNameIndices(nameIndices, text: text)

			if let filteredLives = filteredTypes as? [SVDLiveSet] {
				Model.singleton.filteredLiveSets = filteredLives
			}
		case .Tone:
			let nameIndices = self.nameIndicesForToneTextField(textField)
			filteredTypes = filteredListForNameIndices(nameIndices, text: text)

			if let filteredTones = filteredTypes as? [SVDTone] {
				Model.singleton.filteredTones = filteredTones
			}
		}

		self.updateTableFromList(filteredTypes)
	}

	func resetTextFieldFilters() {
		if let svdFile = self.svdFile {
			let allTypes: [SVDType]

			switch self.svdSubType {
			case .Registration:
				allTypes = svdFile.registrations
				Model.singleton.filteredRegistrations = [SVDRegistration]()
			case .LiveSet:
				allTypes = svdFile.liveSets
				Model.singleton.filteredLiveSets = [SVDLiveSet]()
			case .Tone:
				allTypes = svdFile.tones
				Model.singleton.filteredTones = [SVDTone]()
			}

			self.updateTableFromList(allTypes)
		}
	}

	func nameIndicesForRegistrationTextField(textField: NSTextField) -> [(String, Int)] {
		var nameIndices: [(String, Int)] = []
		var index = 0

		for svdReg in self.tableData as! [SVDRegistration] {
			if let name = self.nameForRegistrationTextField(textField, svdReg: svdReg) {
				nameIndices.append((name, index))
			}

			index += 1
		}

		return nameIndices
	}

	func nameIndicesForLiveSetTextField(textField: NSTextField) -> [(String, Int)] {
		var nameIndices: [(String, Int)] = []
		var index = 0

		for svdLive in self.tableData as! [SVDLiveSet] {
			if let name = self.nameForLiveSetTextField(textField, svdLive: svdLive) {
				nameIndices.append((name, index))
			}

			index += 1
		}

		return nameIndices
	}

	func nameIndicesForToneTextField(textField: NSTextField) -> [(String, Int)] {
		var nameIndices: [(String, Int)] = []
		var index = 0

		for svdTone in self.tableData as! [SVDTone] {
			if let name = self.nameForToneTextField(textField, svdTone: svdTone) {
				nameIndices.append((name, index))
			}

			index += 1
		}

		return nameIndices
	}

	func nameForRegistrationTextField(textField: NSTextField, svdReg: SVDRegistration) -> String? {
		var name: String?

		if textField == self.nameTextField {
			name = svdReg.regName
		} else if let layer1TextField = self.layer1TextField where textField == layer1TextField {
			name = svdReg.upperName
		} else if let layer2TextField = self.layer2TextField where textField == layer2TextField {
			name = svdReg.lowerName
		} else if let layer3TextField = self.layer3TextField where textField == layer3TextField {
			name = svdReg.soloName
		} else if let layer4TextField = self.layer4TextField where textField == layer4TextField {
			name = svdReg.percName
		}

		return name
	}

	func nameForLiveSetTextField(textField: NSTextField, svdLive: SVDLiveSet) -> String? {
		var name: String?

		if textField == self.nameTextField {
			name = svdLive.liveName
		} else if let layer1TextField = self.layer1TextField where textField == layer1TextField {
			name = svdLive.layer1Name
		} else if let layer2TextField = self.layer2TextField where textField == layer2TextField {
			name = svdLive.layer2Name
		} else if let layer3TextField = self.layer3TextField where textField == layer3TextField {
			name = svdLive.layer3Name
		} else if let layer4TextField = self.layer4TextField where textField == layer4TextField {
			name = svdLive.layer4Name
		}

		return name
	}

	func nameForToneTextField(textField: NSTextField, svdTone: SVDTone) -> String? {
		var name: String?

		if textField == self.nameTextField {
			name = svdTone.toneName
		} else if let layer1TextField = self.layer1TextField where textField == layer1TextField {
			name = svdTone.partial1Name
		} else if let layer2TextField = self.layer2TextField where textField == layer2TextField {
			name = svdTone.partial2Name
		} else if let layer3TextField = self.layer3TextField where textField == layer3TextField {
			name = svdTone.partial3Name
		}

		return name
	}

	// MARK: Text field delegate

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
					} else {
						// TODO:
						// Reset the search filter by calling filterDependencies()
						// Filter based on the content of ALL filter text fields

						// Only process the text field when text was entered
						if self.tableData.count > 0 &&
							textField.stringValue.characters.count > 0 {
							filterOnTextField(textField)
						} else {
							resetTextFieldFilters()
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
