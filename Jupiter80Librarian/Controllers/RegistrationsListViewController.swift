//
//  RegistrationsListViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 14/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class RegistrationsListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var orderTextField: NSTextField!
	@IBOutlet var nameTextField: NSTextField!
	@IBOutlet var upperTextField: NSTextField!
	@IBOutlet var lowerTextField: NSTextField!
	@IBOutlet var soloTextField: NSTextField!
	@IBOutlet var percTextField: NSTextField!

	@IBOutlet var tableView: NSTableView!
	@IBOutlet var orderColumn: NSTableColumn!
	@IBOutlet var nameColumn: NSTableColumn!
	@IBOutlet var upperColumn: NSTableColumn!
	@IBOutlet var lowerColumn: NSTableColumn!
	@IBOutlet var soloColumn: NSTableColumn!
	@IBOutlet var percColumn: NSTableColumn!

	var model = Model.singleton
	var svdFile: SVDFile?
	var isInitSound = false

	var lastValidOrderText = ""

    override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
        super.viewDidLoad()

		self.svdFile = self.model.openedSVDFile
		self.tableView.reloadData()
	}

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		var nrOfRows = 0

		if self.svdFile != nil {
			nrOfRows = self.svdFile!.registrations.count
		}

		return nrOfRows
	}

	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		// Retrieve to get the view from the pool or,
		// if no version is available in the pool, load the Interface Builder version
		var result = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner:self) as NSTableCellView
		result.textField?.textColor = NSColor.blackColor()

		var columnValue: String = ""
		var textColor = NSColor.blackColor()

		let svdReg = self.svdFile!.registrations[row]

		if tableColumn == self.nameColumn {
			columnValue = svdReg.regName
			textColor = self.textColorForRegistrationName(columnValue)
		} else if tableColumn == self.orderColumn {
			columnValue = "\(row + 1)"
		} else if tableColumn == self.upperColumn {
			columnValue = svdReg.upperLiveSet.liveName
			textColor = self.textColorForLiveSetName(columnValue)
		} else if tableColumn == self.lowerColumn {
			if self.svdFile != nil {
				if self.svdFile!.fileFormat == .Jupiter80 {
					columnValue = svdReg.lowerLiveSet.liveName
					textColor = self.textColorForLiveSetName(columnValue)
				} else {
					columnValue = "NOT USED"
					textColor = NSColor.lightGrayColor()
				}
			}
		} else if tableColumn == self.soloColumn {
			if svdReg.soloTone != nil {
				columnValue = svdReg.soloTone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else {
				columnValue = svdReg.soloName
				textColor = self.textColorForPartType(svdReg.soloToneType!)
			}
		} else if tableColumn == self.percColumn {
			if svdReg.percTone != nil {
				columnValue = svdReg.percTone!.toneName
				textColor = self.textColorForToneName(columnValue)
			} else {
				columnValue = svdReg.percName
				textColor = self.textColorForPartType(svdReg.percToneType!)
			}
		}

		result.textField?.stringValue = columnValue
		result.textField?.textColor = textColor

		return result
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

	func textColorForToneName(toneName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		if self.isInitSound == true || toneName == "INIT SYNTH" {
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

	func textColorForRegistrationName(regName: String) -> NSColor {
		var textColor = NSColor.blackColor()

		self.isInitSound = false

		if regName == "INIT REGIST" {
			textColor = .lightGrayColor()
			self.isInitSound = true
		}

		return textColor
	}

	func svdFileDidUpdate(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.svdFile = self.model.openedSVDFile

			self.tableView.reloadData()
		}
	}

	override func controlTextDidChange(obj: NSNotification) {
		if let textField = obj.object as? NSTextField {
			// The order field must contain a valid number
			if textField == self.orderTextField {
				var isValidTextField = false
				let text = textField.stringValue

				if let svdFile = self.svdFile? {
					if countElements(text) > 0 {
						if let order = text.toInt() {
							// The number is valid if it is between the min and max nr of registrations
							if order >= 1 && order <= svdFile.registrations.count {
								isValidTextField = true
							}
						}
					}
					// The number is valid if the field is empty
					else {
						isValidTextField = true
					}
				}

				// Store the entered number if it is valid
				if isValidTextField == true {
					self.lastValidOrderText = text
				}
				// Restore the last valid number if the current is invalid
				else {
					textField.stringValue = self.lastValidOrderText
				}
			}
		}
	}

	override func controlTextDidEndEditing(obj: NSNotification) {
		if let textMovement = obj.userInfo?["NSTextMovement"] as? Int {
			// Only process the text field when the Return key was pressed
			if textMovement == NSReturnTextMovement {
				if let textField = obj.object as? NSTextField {
					var indices = [Int]()

					// The order field matches one and only one row number
					if textField == self.orderTextField {
						let text = textField.stringValue

						// Only process the text field when text was entered
						if countElements(text) > 0 {
							if let order = text.toInt() {
								let index = order - 1
								indices.append(index)
							}
						}
					}
					// The other fields match any number of rows containing the text
					// Only process the text field if an SVD file is open
					else if let svdFile = self.svdFile? {
						let text = textField.stringValue.lowercaseString

						// Only process the text field when text was entered
						if countElements(text) > 0 {
							var keyName = ""

							// Decide which property to look up dynamically by key path
							if textField == self.nameTextField {
								keyName = "regName"
							} else if textField == self.upperTextField {
								keyName = "upperName"
							} else if textField == self.lowerTextField {
								keyName = "lowerName"
							} else if textField == self.soloTextField {
								keyName = "soloName"
							} else if textField == self.percTextField {
								keyName = "percName"
							}

							var index = 0

							for registration in svdFile.registrations {
								if let name = registration.valueForKey(keyName) as String? {
									if name.lowercaseString.hasPrefix(text) {
										indices.append(index)
									}
								}

								index++
							}
						}
					}

					// If any rows were matched
					if indices.count > 0 {
						var indexSet = NSMutableIndexSet()

						for index in indices {
							indexSet.addIndex(index)
						}

						// Select all matched rows
						self.tableView.selectRowIndexes(indexSet, byExtendingSelection: false)

						// Scroll to the first matched row
						if let index = indices.first? {
							let rect = self.tableView.rectOfRow(index)
							self.tableView.scrollPoint(CGPoint(x: 0, y: rect.origin.y - rect.size.height))
						}
					}
				}
			}
		}
	}
}
