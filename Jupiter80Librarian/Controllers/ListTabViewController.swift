//
//  ListTabViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class ListTabViewController: NSTabViewController {
	@IBOutlet var regTabViewItem: NSTabViewItem!
	@IBOutlet var liveTabViewItem: NSTabViewItem!
	@IBOutlet var toneTabViewItem: NSTabViewItem!

	var model = Model.singleton
	var svdFile: SVDFile?

	override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "svdFileDidUpdate:", name: "svdFileDidUpdate", object: nil)
		super.viewDidLoad()
	}

	func svdFileDidUpdate(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.svdFile = self.model.openedSVDFile

			if self.svdFile != nil {
				self.regTabViewItem.label = "Registrations (\(self.svdFile!.nrOfRegs))"
				self.liveTabViewItem.label = "Live sets (\(self.svdFile!.nrOfLives))"
				self.toneTabViewItem.label = "Tones (\(self.svdFile!.nrOfTones))"
			}
		}
	}
}
