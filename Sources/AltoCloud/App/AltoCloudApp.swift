import AppKit
import SwiftUI

@main
struct AltoCloudApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DemoStore()

    var body: some Scene {
        WindowGroup("Alto Cloud", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 900, minHeight: 660)
        }
        .commands {
            CommandMenu("Shared Cloud") {
                Button(store.sharedCloudSession.isActive ? "Stop Shared Cloud" : "Start Shared Cloud") {
                    store.toggleSharedCloud()
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button("Add Sample File") {
                    store.addSampleFile()
                }
                .keyboardShortcut("u", modifiers: [.command])
                .disabled(!store.sharedCloudSession.isActive)
            }
        }

        MenuBarExtra {
            MenuBarStatusView(store: store)
        } label: {
            MenuBarLogo()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
        return false
    }
}

struct MenuBarStatusView: View {
    @ObservedObject var store: DemoStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Alto Cloud") {
            NSApp.setActivationPolicy(.regular)
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button(store.sharedCloudSession.isActive ? "Stop Shared Cloud" : "Start Shared Cloud") {
            store.toggleSharedCloud()
        }

        Button("Add Sample File") {
            store.addSampleFile()
        }
        .disabled(!store.sharedCloudSession.isActive)

        Divider()

        Text("Browser: \(store.lanBrowserState)")
        Text("Peer: \(store.peerAdvertiseState)")
        Text("Shared Cloud: \(store.sharedCloudAdvertiseState)")

        Divider()

        Button("Quit Alto Cloud") {
            NSApplication.shared.terminate(nil)
        }
    }
}

struct MenuBarLogo: View {
    var body: some View {
        if let image = NSImage(named: "MenuBarIcon") {
            Image(nsImage: configuredTemplate(image))
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: "cloud")
        }
    }

    private func configuredTemplate(_ image: NSImage) -> NSImage {
        image.isTemplate = true
        return image
    }
}
