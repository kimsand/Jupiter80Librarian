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

	private let model = Model.singleton
	private var svdFile: SVDFile?

    // MARK: - Lifecycle

	override func viewDidLoad() {
		NotificationCenter.default.addObserver(self, selector: #selector(ListTabViewController.svdFileDidUpdate(_:)), name: NSNotification.Name(rawValue: "svdFileDidUpdate"), object: nil)
		super.viewDidLoad()
	}

    // MARK: - Tab view delegate

    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        // In a tab view that has different widths for its tabs, the inactive
        // tabs need to disable a horizontal constraint that would otherwise
        // break the layout of the active tab, since the widths are in conflict.
        // There might be a better way to solve this, but this is the only one
        // I have found so far.
        if let viewController = tabView.selectedTabViewItem?.viewController as? SuperListViewController {
            viewController.deactivateBreakingLayoutConstraint()
        }

        if let viewController = tabViewItem?.viewController as? SuperListViewController {
            viewController.activateBreakingLayoutConstraint()
        }
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        // Animate window resizing so it appears smooth
        NSAnimationContext.runAnimationGroup { (context) in
            context.allowsImplicitAnimation = true
            if let window = NSApplication.shared.mainWindow {
                window.layoutIfNeeded()
            }
        }
    }
}

// MARK: - Notifications

extension ListTabViewController {
    @objc func svdFileDidUpdate(_ notification: Notification) {
        DispatchQueue.main.async {
            self.svdFile = self.model.openedSVDFile

            if let svdFile = self.svdFile {
                self.regTabViewItem.label = "Registrations (\(svdFile.nrOfRegs))"
                self.liveTabViewItem.label = "Live sets (\(svdFile.nrOfLives))"
                self.toneTabViewItem.label = "Tones (\(svdFile.nrOfTones))"
            }
        }
    }
}
