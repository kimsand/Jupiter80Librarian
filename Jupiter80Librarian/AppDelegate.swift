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
	var model: Model?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		self.model = Model.singleton
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let fileURL = URL(fileURLWithPath: filename)
		self.openFileURL(fileURL)

		return true
	}

	@objc func openDocument(_ sender: AnyObject) {
		let openPanel = NSOpenPanel()

		openPanel.title = "Roland Jupiter-80/50 SVD file to open"
		openPanel.allowedFileTypes = ["svd", "SVD"]
		openPanel.canChooseDirectories = false

		let status = openPanel.runModal()

		var fileURL: URL?

        if status == NSApplication.ModalResponse.OK {
			fileURL = openPanel.urls.first as URL?

			openPanel.close()
		}

		// Give the open dialog time to close to avoid it staying open on breakpoints
		DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
			if let fileURL = fileURL {
				self.openFileURL(fileURL)
			}
		})
	}

	func openFileURL(_ fileURL: URL) {
		self.model!.fileName = fileURL.lastPathComponent
		NotificationCenter.default.post(name: Notification.Name(rawValue: "svdFileWasChosen"), object: nil)
		NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)

		DLog("fileURL: \(fileURL)")

		var error: NSError?
		let fileData: Data?
		do {
			fileData = try Data(contentsOf: fileURL, options: [])
		} catch let error1 as NSError {
			error = error1
			fileData = nil
		} catch {
			fatalError()
		}

		if fileData != nil && error == nil {
			DLog("file length:\(fileData!.count)")

			let svdFile = SVDFile(fileData: fileData!)
			self.model!.openedSVDFile = svdFile

			NotificationCenter.default.post(name: Notification.Name(rawValue: "svdFileDidUpdate"), object: nil)
		} else if error != nil {
			DLog("error:\(error!)")
		}
	}
}
