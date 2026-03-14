import AppKit
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let bottleManager = BottleManager()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single instance guard
        let running = NSWorkspace.shared.runningApplications
        let pid = ProcessInfo.processInfo.processIdentifier
        let bundle = Bundle.main.bundleIdentifier ?? ""
        if running.contains(where: { $0.bundleIdentifier == bundle && $0.processIdentifier != pid }) {
            NSApp.terminate(nil)
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "CXRes")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func switchToProfile(_ sender: NSMenuItem) {
        bottleManager.apply(sender.representedObject as? ResolutionProfile)
    }

    @objc private func switchBottle(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        AppSettings.bottleName = name
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if sender.state == .on {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("CXRes: launch-at-login toggle failed: \(error)")
        }
    }

    @objc private func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "CXRes Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }
}

// MARK: - Menu

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let header = NSMenuItem(title: "CrossOver Resolution", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let current = bottleManager.currentProfile()

        // Off
        let offItem = NSMenuItem(
            title: "Off — No Virtual Desktop",
            action: #selector(switchToProfile(_:)),
            keyEquivalent: "0"
        )
        offItem.target = self
        offItem.state = current == nil ? .on : .off
        menu.addItem(offItem)

        // Profiles
        for (i, profile) in AppSettings.profiles.enumerated() {
            let item = NSMenuItem(
                title: "\(profile.name) — \(profile.resolution)",
                action: #selector(switchToProfile(_:)),
                keyEquivalent: i < 9 ? "\(i + 1)" : ""
            )
            item.target = self
            item.representedObject = profile
            item.state = current?.id == profile.id ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Bottle picker — only shown when multiple bottles exist
        let bottles = AppSettings.availableBottles()
        if bottles.count > 1 {
            let bottleMenu = NSMenu()
            for bottle in bottles {
                let item = NSMenuItem(
                    title: bottle,
                    action: #selector(switchBottle(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = bottle
                item.state = bottle == AppSettings.bottleName ? .on : .off
                bottleMenu.addItem(item)
            }
            let bottleItem = NSMenuItem(title: "Bottle: \(AppSettings.bottleName)", action: nil, keyEquivalent: "")
            bottleItem.submenu = bottleMenu
            menu.addItem(bottleItem)
            menu.addItem(.separator())
        }

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit CXRes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
}
