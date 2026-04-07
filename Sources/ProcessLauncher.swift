import Foundation
import Combine
import AppKit

class ProcessLauncher: ObservableObject {
    @Published var proxyPort: String = "10808" {
        didSet {
            UserDefaults.standard.set(proxyPort, forKey: "AetherProxyPort")
        }
    }
    
    @Published var isLaunching: Bool = false
    @Published var statusMessage: String = ""
    
    init() {
        if let savedPort = UserDefaults.standard.string(forKey: "AetherProxyPort") {
            self.proxyPort = savedPort
        }
    }
    
    func launchAntigravitySecurely() {
        self.isLaunching = true
        self.statusMessage = "Launching..."
        
        let appURL = URL(fileURLWithPath: "/Applications/Antigravity.app")
        
        if !FileManager.default.fileExists(atPath: appURL.path) {
            DispatchQueue.main.async {
                self.statusMessage = "❌ Antigravity not found at /Applications/"
                self.isLaunching = false
            }
            return
        }
        
        let config = NSWorkspace.OpenConfiguration()
        var env = ProcessInfo.processInfo.environment
        env["HTTP_PROXY"] = "http://127.0.0.1:\(self.proxyPort)"
        env["HTTPS_PROXY"] = "http://127.0.0.1:\(self.proxyPort)"
        env["ALL_PROXY"] = "socks5://127.0.0.1:\(self.proxyPort)"
        env["NO_PROXY"] = "localhost,127.0.0.1,::1"
        config.environment = env
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMessage = "❌ Error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "✅ Launched securely via NSWorkspace!"
                }
                self.isLaunching = false
            }
        }
    }
}
