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
        let httpProxy = "http://127.0.0.1:\(self.proxyPort)"
        let socksProxy = "socks5://127.0.0.1:\(self.proxyPort)"
        
        // Comprehensive Node.js and gRPC proxy environment variables
        env["HTTP_PROXY"] = httpProxy
        env["HTTPS_PROXY"] = httpProxy
        env["ALL_PROXY"] = socksProxy
        env["NO_PROXY"] = "localhost,127.0.0.1,::1"
        env["GLOBAL_AGENT_HTTP_PROXY"] = httpProxy
        env["GLOBAL_AGENT_HTTPS_PROXY"] = httpProxy
        env["grpc_proxy"] = httpProxy
        
        config.environment = env
        
        // Pass Chromium proxy flags directly to the Electron executable
        config.arguments = [
            "--proxy-server=\(socksProxy)",
            "--host-resolver-rules=MAP * ~NOTFOUND , EXCLUDE 127.0.0.1"
        ]
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMessage = "❌ Error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "✅ Launched with Electron proxies!"
                }
                self.isLaunching = false
            }
        }
    }
}
