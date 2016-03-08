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
}
