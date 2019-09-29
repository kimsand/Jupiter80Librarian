//
//  ListWindowController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 20/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class ListWindowController: NSWindowController {
    private let model = Model.singleton

    // MARK: - Lifecycle

    override func windowDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(ListWindowController.svdFileWasChosen(_:)), name: NSNotification.Name(rawValue: "svdFileWasChosen"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(ListWindowController.svdFileIsInvalid(_:)), name: NSNotification.Name(rawValue: "svdFileIsInvalid"), object: nil)

		super.windowDidLoad()

		window?.title = "Open a Jupiter-80/50 SVD file"
    }
}

// MARK: - Notifications

extension ListWindowController {
	@objc func svdFileWasChosen(_ notification: Notification) {
		DispatchQueue.main.async {
            if let fileName = self.model.fileName {
				self.window?.title = fileName
			}

            // Make sure the window is visible, in case it has been closed
            self.window?.makeKeyAndOrderFront(self)
		}
	}

	@objc func svdFileIsInvalid(_ notification: Notification) {
		DispatchQueue.main.async {
            if self.model.fileName != nil {
				self.window?.title = "Not a valid Jupiter-80/50 SVD file"
			}
		}
	}
}
