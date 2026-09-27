// Fn Switch — menu bar toggle for "Use F1, F2, etc. keys as standard function keys".
// Left-click the icon to toggle; right-click (or ctrl-click) for the menu.

import AppKit
import IOKit
import IOKit.hidsystem
import ServiceManagement

enum FnKeys {
    private static func connect() -> io_connect_t? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var conn: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &conn) == KERN_SUCCESS else { return nil }
        return conn
    }

    /// true = F1, F2… act as standard function keys (media keys need fn).
    static var standardMode: Bool {
        get {
            guard let c = connect() else { return false }
            defer { IOServiceClose(c) }
            var value: UInt32 = 0
            var size: IOByteCount = 0
            IOHIDGetParameter(c, kIOHIDFKeyModeKey as CFString, IOByteCount(MemoryLayout<UInt32>.size), &value, &size)
            return value != 0
        }
        set {
            guard let c = connect() else { return }
            defer { IOServiceClose(c) }
            var value: UInt32 = newValue ? 1 : 0
            IOHIDSetParameter(c, kIOHIDFKeyModeKey as CFString, &value, IOByteCount(MemoryLayout<UInt32>.size))
            // Keep the saved preference in sync so System Settings shows the same state.
            CFPreferencesSetValue("com.apple.keyboard.fnState" as CFString, newValue as CFBoolean,
                                  kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let toggleItem = NSMenuItem(title: "Use F1, F2, etc. as standard function keys", action: #selector(toggle), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        toggleItem.target = self
        loginItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem(title: "Quit Fn Switch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.delegate = self

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            // Optional "pressed" icon, shown while the mouse button is held down
            // instead of the usual grey highlight — like a physical key going down.
            if let pressed = NSImage(named: "fn-pressed") {
                pressed.isTemplate = false
                button.alternateImage = pressed
                (button.cell as? NSButtonCell)?.highlightsBy = .contentsCellMask
            }
        }
        refresh()
    }

    @objc private func clicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggle()
        }
    }

    @objc private func toggle() {
        FnKeys.standardMode.toggle()
        refresh()
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        if service.status == .enabled { try? service.unregister() } else { try? service.register() }
        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) { refresh() }

    private func refresh() {
        let on = FnKeys.standardMode
        toggleItem.state = on ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        guard let button = statusItem.button else { return }
        // "F1" = standard function keys; "fn" + sun icon = media/brightness keys.
        // Custom icons from icons/ (copied into the app's Resources); falls back to text.
        if let image = NSImage(named: on ? "fn-on" : "fn-off") {
            image.isTemplate = false // show the icon in its own colors
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = on ? "F1" : "☀︎"
            button.font = .monospacedSystemFont(ofSize: 13, weight: on ? .bold : .regular)
        }
        button.toolTip = on ? "F-keys: standard F1, F2… (click to switch to media keys)"
                            : "F-keys: media/brightness (click to switch to F1, F2…)"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
