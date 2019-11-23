//
//  AppDelegate.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 19/11/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowService = WindowService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start with a blank window to show the UI before a file is loaded
        let windowController = ListWindowController.createBlank()
        windowService.createWindow(newWindowController: windowController, ordered: .above)
        windowController.showWindow(self)
    }

	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let fileURL = URL(fileURLWithPath: filename)
		openFileURL(fileURL)

		return true
	}

	func openFileURL(_ fileURL: URL) {
		DLog("File URL: \(fileURL)")

		do {
			let fileData = try Data(contentsOf: fileURL, options: [])
            DLog("File size: \(fileData.count)")

            let svdFile = SVDFile(fileData: fileData)
            guard svdFile.isFileValid else {
                DLog("Not a valid Jupiter-80/50 SVD file")
                return
            }

            let fileName = fileURL.lastPathComponent

            let model = Model()
            model.openedSVDFile = svdFile
            model.fileName = fileName

            let windowController: ListWindowController

            // Reuse the blank window if it is the only window opened
            if
                windowService.managedWindows.count == 1,
                let blankController = windowService.managedWindows.first?.windowController as? ListWindowController,
                !blankController.hasLoadedModel {
                windowController = blankController
                windowController.load(model: model)
            } else {
                windowController = ListWindowController.create(model: model)
                windowService.createWindow(newWindowController: windowController, ordered: .above)
            }

            windowController.showWindow(self)

            NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
		} catch let error as NSError {
            DLog("File error: \(error)")
		}
    }

    // MARK: - Actions

    @objc func openDocument(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()

        openPanel.title = "Roland Jupiter-80/50 SVD file to open"
        openPanel.allowedFileTypes = ["svd", "SVD"]
        openPanel.canChooseDirectories = false

        let status = openPanel.runModal()

        guard
            status == NSApplication.ModalResponse.OK,
            let fileURL = openPanel.urls.first as URL?
        else { return }

        openPanel.close()

        // Give the open dialog time to close to avoid it staying open on breakpoints
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
            self.openFileURL(fileURL)
        })
    }
}
