import AppKit
import SwiftUI
import WidgetKit

@main
struct TimeZonesWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appGroupManager = AppGroupManager.shared
    @StateObject private var timeManager = TimeManager()
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appGroupManager)
                .environmentObject(timeManager)
                .frame(minWidth: 320, idealWidth: 320, minHeight: 360, idealHeight: 360)
                .modifier(AppThemeApplier(theme: appGroupManager.config.appTheme))
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appGroupManager)
                .modifier(AppThemeApplier(theme: appGroupManager.config.appTheme))
        }
        #endif
    }
}

private struct AppThemeApplier: ViewModifier {
    let theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                applyTheme(theme)
            }
            .onChange(of: theme) { newValue in
                applyTheme(newValue)
            }
    }

    private func applyTheme(_ theme: AppTheme) {
        DispatchQueue.main.async {
            switch theme {
            case .system:
                NSApp.appearance = nil
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static weak var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private weak var mainWindow: NSWindow?
    private var settingsWindowController: NSWindowController?

    private lazy var statusMenu: NSMenu = {
        let menu = NSMenu()

        let aboutItem = NSMenuItem(
            title: "About",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Application",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }()

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        // Force desktop widgets to refresh after app launch (helps after rebuild/deploy).
        WidgetCenter.shared.reloadAllTimelines()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func registerMainWindow(_ window: NSWindow) {
        guard mainWindow !== window else { return }
        mainWindow = window
        window.delegate = self
        configureMainWindow(window)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard sender == mainWindow else { return true }
        sender.orderOut(nil)
        hideFromDock()
        return false
    }

    private func configureMainWindow(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.title = ""
        window.isMovableByWindowBackground = true
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        if let button = item.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Time Zones")
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Time Zones"
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            toggleMainWindow()
            return
        }

        switch event.type {
        case .rightMouseUp:
            showStatusMenu()
        default:
            toggleMainWindow()
        }
    }

    private func showStatusMenu() {
        guard let statusItem = statusItem else { return }
        statusItem.menu = statusMenu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func toggleMainWindow() {
        guard let window = mainWindow else { return }

        if window.isVisible {
            window.orderOut(nil)
            hideFromDock()
        } else {
            showInDock()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showInDock() {
        NSApp.setActivationPolicy(.regular)
    }

    private func hideFromDock() {
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func openSettings() {
        let controller = makeSettingsWindowControllerIfNeeded()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)

        let description = """
        A simple app for tracking time across multiple time zones.
        Created by: Dmitry Marchenko (@dmitrobuber)
        """

        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "TimeZonesWidget",
            .applicationVersion: shortVersion,
            .version: buildVersion,
            .credits: NSAttributedString(string: description)
        ])
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func makeSettingsWindowControllerIfNeeded() -> NSWindowController {
        if let controller = settingsWindowController {
            return controller
        }

        let settingsRoot = SettingsView()
            .environmentObject(AppGroupManager.shared)
            .modifier(AppThemeApplier(theme: AppGroupManager.shared.config.appTheme))

        let hostingController = NSHostingController(rootView: settingsRoot)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "TimeZonesWidget Settings"
        window.titleVisibility = .visible
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 420, height: 320))
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        return controller
    }
}

struct MainWindowView: View {
    var body: some View {
        ContentView()
            .background(WindowAccessor { window in
                AppDelegate.shared?.registerMainWindow(window)
            })
    }
}

struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onWindow(window)
            }
        }
    }
}
