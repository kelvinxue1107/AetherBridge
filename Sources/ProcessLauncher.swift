import Foundation
import Combine
import AppKit

@MainActor
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
        isLaunching = true
        statusMessage = "Launching Antigravity..."
        
        let appURL = URL(fileURLWithPath: "/Applications/Antigravity.app")
        
        if !FileManager.default.fileExists(atPath: appURL.path) {
            statusMessage = "❌ Antigravity not found at /Applications/"
            isLaunching = false
            return
        }
        
        let port = self.proxyPort
        
        let config = NSWorkspace.OpenConfiguration()
        
        // Set proxy environment variables
        var env = ProcessInfo.processInfo.environment
        let httpProxy = "http://127.0.0.1:\(port)"
        let socksProxy = "socks5://127.0.0.1:\(port)"
        env["HTTP_PROXY"] = httpProxy
        env["HTTPS_PROXY"] = httpProxy
        env["ALL_PROXY"] = socksProxy
        env["http_proxy"] = httpProxy
        env["https_proxy"] = httpProxy
        env["all_proxy"] = socksProxy
        env["GLOBAL_AGENT_HTTP_PROXY"] = httpProxy
        env["GLOBAL_AGENT_HTTPS_PROXY"] = httpProxy
        env["NO_PROXY"] = "localhost,127.0.0.1,::1"
        env["no_proxy"] = "localhost,127.0.0.1,::1"
        env["grpc_proxy"] = httpProxy
        config.environment = env
        
        // Chromium proxy flags
        config.arguments = [
            "--proxy-server=socks5://127.0.0.1:\(port)",
            "--disable-quic"
        ]
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMessage = "❌ Error: \(error.localizedDescription)"
                } else if let app = app {
                    self.statusMessage = "✅ Antigravity launched! (PID: \(app.processIdentifier))"
                } else {
                    self.statusMessage = "✅ Antigravity launched!"
                }
                self.isLaunching = false
            }
        }
    }
}
