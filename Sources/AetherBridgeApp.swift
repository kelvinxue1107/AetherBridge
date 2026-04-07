import SwiftUI
import AppKit

@main
struct AetherBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var launcher = ProcessLauncher()

    var body: some Scene {
        MenuBarExtra("AetherBridge", systemImage: "link.icloud") {
            VStack(alignment: .leading, spacing: 8) {
                Text("AetherBridge Launcher")
                    .font(.headline)
                
                HStack {
                    Text("VLESS Port:")
                    TextField("10808", text: $launcher.proxyPort)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                Button(action: {
                    launcher.launchAntigravitySecurely()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Launch Antigravity Securely")
                    }
                }
                .disabled(launcher.isLaunching)
                
                if !launcher.statusMessage.isEmpty {
                    Text(launcher.statusMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                Button("Quit AetherBridge") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
