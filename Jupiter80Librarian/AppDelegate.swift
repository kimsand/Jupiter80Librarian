//
//  AppDelegate.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 19/11/14.
//  Copyright (c) 2014 Kim André Sand. All rights reserved.
//

import Cocoa

enum FileFormat {
	case Unknown
	case Jupiter80
	case Jupiter50
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
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

		switch(status) {
		case NSFileHandlingPanelOKButton:
			if let fileURL = openPanel.URLs.first? as? NSURL {
				NSLog("fileURL: %@", fileURL)

				var error: NSError?
				let fileData = NSData(contentsOfURL: fileURL, options: nil, error: &error)

				if fileData != nil && error == nil {
					NSLog("file length: %d", fileData!.length)

					SVDUtils.checkValidityOfData(fileData!)
				} else if error != nil {
					NSLog("error: %@", error!)
				}
			}
		default:
			return
		}
	}

}

