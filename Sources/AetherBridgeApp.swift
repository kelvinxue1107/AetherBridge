import SwiftUI
import AppKit

@main
struct AetherBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var configManager = IDEConfigManager()

    var body: some Scene {
        MenuBarExtra("AetherBridge", systemImage: "link.icloud") {
            VStack(alignment: .leading, spacing: 8) {
                Text("AetherBridge")
                    .font(.headline)
                
                HStack {
                    Text("Proxy Port:")
                    TextField("eg. 10808", text: $configManager.proxyPort)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                Toggle("Enable IDE Proxy", isOn: $configManager.isProxyEnabled)
                    .toggleStyle(SwitchToggleStyle())
                
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
