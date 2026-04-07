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
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Find Antigravity IDE
            let appURL = URL(fileURLWithPath: "/Applications/Antigravity.app") // Standard location
            
            // We must launch the raw executable to inject environment variables effectively
            let executableURL = appURL.appendingPathComponent("Contents/MacOS/Antigravity")
            
            if !FileManager.default.fileExists(atPath: executableURL.path) {
                DispatchQueue.main.async {
                    self.statusMessage = "❌ Antigravity not found at /Applications/"
                    self.isLaunching = false
                }
                return
            }
            
            let process = Process()
            process.executableURL = executableURL
            
            // Inject the proxy variables targeting local VLESS node
            var env = ProcessInfo.processInfo.environment
            env["HTTP_PROXY"] = "http://127.0.0.1:\(self.proxyPort)"
            env["HTTPS_PROXY"] = "http://127.0.0.1:\(self.proxyPort)"
            env["ALL_PROXY"] = "socks5://127.0.0.1:\(self.proxyPort)"
            env["NO_PROXY"] = "localhost,127.0.0.1"
            process.environment = env
            
            do {
                try process.run()
                DispatchQueue.main.async {
                    self.statusMessage = "✅ Launched securely!"
                    self.isLaunching = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "❌ Error: \(error.localizedDescription)"
                    self.isLaunching = false
                }
            }
        }
    }
}
