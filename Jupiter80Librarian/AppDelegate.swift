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

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		self.model = Model.singleton
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}

	func openDocument(sender: AnyObject) {
		let openPanel = NSOpenPanel()

		openPanel.title = "Roland Jupiter-80/50 SVD file to open"
		openPanel.allowedFileTypes = ["svd", "SVD"]
		openPanel.canChooseDirectories = false

		let status = openPanel.runModal()

		var fileURL: NSURL?

		switch(status) {
		case NSFileHandlingPanelOKButton:
			fileURL = openPanel.URLs.first as? NSURL
			self.model!.fileName = fileURL?.lastPathComponent
			NSNotificationCenter.defaultCenter().postNotificationName("svdFileWasChosen", object: nil)
			openPanel.close()
		default:
			return
		}

		// Give the open dialog time to close to avoid it staying open on breakpoints
		dispatch_after(dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(0.2 * Double(NSEC_PER_SEC))
			), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
			if fileURL != nil {
				NSLog("fileURL: %@", fileURL!)

				var error: NSError?
				let fileData = NSData(contentsOfURL: fileURL!, options: nil, error: &error)

				if fileData != nil && error == nil {
					NSLog("file length: %d", fileData!.length)

					let svdFile = SVDFile(fileData: fileData!)
					self.model!.openedSVDFile = svdFile

					NSNotificationCenter.defaultCenter().postNotificationName("svdFileDidUpdate", object: nil)
				} else if error != nil {
					NSLog("error: %@", error!)
				}
			}
		})
	}
}
