//
//  ListWindowController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 20/12/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

class ListWindowController: NSWindowController {
    private(set) var hasLoadedModel = false

    // MARK: - Lifecycle

    static func createBlank() -> ListWindowController {
        let windowStoryboard = NSStoryboard(name: "WindowController", bundle: nil)
        let windowController = windowStoryboard.instantiateInitialController() as! ListWindowController

        return windowController
    }

    static func create(model: Model) -> ListWindowController {
        let windowStoryboard = NSStoryboard(name: "WindowController", bundle: nil)
        let windowController = windowStoryboard.instantiateInitialController() as! ListWindowController

        windowController.load(model: model)

        return windowController
    }

    override func windowDidLoad() {
		super.windowDidLoad()

		window?.title = "Open a Jupiter-80/50 SVD file"
    }

    // MARK: - Member methods

    func load(model: Model) {
        if let fileName = model.fileName {
            window?.title = fileName
        }

        if let tabBarController = window?.contentViewController as? ListTabViewController {
            tabBarController.loadModel(model)
        }

        hasLoadedModel = true
    }
}
