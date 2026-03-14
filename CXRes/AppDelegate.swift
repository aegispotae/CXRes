import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let bottleManager = BottleManager()

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
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
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
