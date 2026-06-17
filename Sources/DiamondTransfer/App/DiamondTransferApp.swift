import AppKit
import SwiftUI

@main
struct DiamondTransferApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DemoStore()

    var body: some Scene {
        WindowGroup("Diamond Transfer", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 900, minHeight: 660)
        }
        .commands {
            CommandMenu("Diamond Cloud") {
                Button(store.hubSession.isActive ? "Stop Diamond Cloud" : "Start Diamond Cloud") {
                    store.toggleHub()
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Button("Add Sample File") {
                    store.addSampleFile()
                }
                .keyboardShortcut("u", modifiers: [.command])
                .disabled(!store.hubSession.isActive)
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
        Button("Show Diamond Transfer") {
            NSApp.setActivationPolicy(.regular)
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button(store.hubSession.isActive ? "Stop Diamond Cloud" : "Start Diamond Cloud") {
            store.toggleHub()
        }

        Button("Add Sample File") {
            store.addSampleFile()
        }
        .disabled(!store.hubSession.isActive)

        Divider()

        Text("Browser: \(store.lanBrowserState)")
        Text("Peer: \(store.peerAdvertiseState)")
        Text("Cloud: \(store.hubAdvertiseState)")

        Divider()

        Button("Quit Diamond Transfer") {
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
            Image(systemName: "diamond")
        }
    }

    private func configuredTemplate(_ image: NSImage) -> NSImage {
        image.isTemplate = true
        return image
    }
}
