//
//  ListTabViewController.swift
//  Jupiter80Librarian
//
//  Created by Kim André Sand on 17/12/14.
//

import Cocoa

class ListTabViewController: NSTabViewController {
	@IBOutlet var regTabViewItem: NSTabViewItem!
	@IBOutlet var liveTabViewItem: NSTabViewItem!
	@IBOutlet var toneTabViewItem: NSTabViewItem!

    // MARK: - Tab view delegate

    func loadModel(_ model: Model) {
        tabViewItems.forEach({ tabViewItem in
            if let viewController = tabViewItem.viewController as? SuperListViewController {
                viewController.loadModel(model)
            }
        })
    }

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
        if #available(OSX 10.12, *) {
            NSAnimationContext.runAnimationGroup { (context) in
                context.allowsImplicitAnimation = true
                if let window = NSApplication.shared.mainWindow {
                    window.layoutIfNeeded()
                }
            }
        }
    }
}
