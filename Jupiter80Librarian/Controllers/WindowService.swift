//
//  WindowService.swift
//  Jupiter-80 Librarian
//
//  Created by Kim André Sand on 17/11/2019.
//  Copyright © 2019 Kim André Sand. All rights reserved.
//

import Cocoa

class WindowService {
    struct ManagedWindow {
        let windowController: NSWindowController
        let window: NSWindow
        let closingSubscription: NotificationToken
    }

    fileprivate(set) var managedWindows: [ManagedWindow] = []

    func createWindow(newWindowController: ListWindowController,
                   ordered orderingMode: NSWindow.OrderingMode) {
        guard let newWindow = addManagedWindow(windowController: newWindowController)?.window else { preconditionFailure() }

        newWindow.makeKeyAndOrderFront(nil)
    }

    private func addManagedWindow(windowController: ListWindowController) -> ManagedWindow? {
        guard let window = windowController.window else { return nil }

        let subscription = NotificationCenter.default.observe(name: NSWindow.willCloseNotification, object: window) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            self?.removeManagedWindow(forWindow: window)
        }

        let management = ManagedWindow(
            windowController: windowController,
            window: window,
            closingSubscription: subscription
        )

        managedWindows.append(management)

        return management
    }

    private func removeManagedWindow(forWindow window: NSWindow) {
        managedWindows.removeAll(where: { $0.window === window })
    }
}
