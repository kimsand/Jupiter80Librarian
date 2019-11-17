//
//  ListWindowController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 20/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class ListWindowController: NSWindowController {
    // MARK: - Lifecycle

    static func create(model: Model) -> ListWindowController {
        let windowStoryboard = NSStoryboard(name: "WindowController", bundle: nil)
        let windowController = windowStoryboard.instantiateInitialController() as! ListWindowController

        if let fileName = model.fileName {
            windowController.window?.title = fileName
        }

        if let tabBarController = windowController.window?.contentViewController as? ListTabViewController {
            tabBarController.loadModel(model)
        }

        return windowController
    }

    override func windowDidLoad() {
		super.windowDidLoad()

		window?.title = "Open a Jupiter-80/50 SVD file"
    }
}
