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
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListWindowController.svdFileWasChosen(_:)), name: "svdFileWasChosen", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListWindowController.svdFileIsInvalid(_:)), name: "svdFileIsInvalid", object: nil)

		super.windowDidLoad()

		self.window!.title = "Open a Jupiter-80/50 SVD file"
    }

	func svdFileWasChosen(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			if Model.singleton.fileName != nil {
				self.window!.title = Model.singleton.fileName!

				// Make sure the window is visible, in case it has been closed
				self.window!.makeKeyAndOrderFront(self)
			}
		}
	}

	func svdFileIsInvalid(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			if Model.singleton.fileName != nil {
				self.window!.title = "Not a valid Jupiter-80/50 SVD file"
			}
		}
	}
}
