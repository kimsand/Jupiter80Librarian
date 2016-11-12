//
//  ListWindowController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 20/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class ListWindowController: NSWindowController {
    override func windowDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(ListWindowController.svdFileWasChosen(_:)), name: NSNotification.Name(rawValue: "svdFileWasChosen"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(ListWindowController.svdFileIsInvalid(_:)), name: NSNotification.Name(rawValue: "svdFileIsInvalid"), object: nil)

		super.windowDidLoad()

		self.window!.title = "Open a Jupiter-80/50 SVD file"
    }

	func svdFileWasChosen(_ notification: Notification) {
		DispatchQueue.main.async { () -> Void in
			if Model.singleton.fileName != nil {
				self.window!.title = Model.singleton.fileName!

				// Make sure the window is visible, in case it has been closed
				self.window!.makeKeyAndOrderFront(self)
			}
		}
	}

	func svdFileIsInvalid(_ notification: Notification) {
		DispatchQueue.main.async { () -> Void in
			if Model.singleton.fileName != nil {
				self.window!.title = "Not a valid Jupiter-80/50 SVD file"
			}
		}
	}
}
