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
        self.statusMessage = "Setting up secure clone..."
        
        let fm = FileManager.default
        let sourcePath = "/Applications/Antigravity.app"
        
        if !fm.fileExists(atPath: sourcePath) {
            DispatchQueue.main.async {
                self.statusMessage = "❌ Antigravity not found at /Applications/"
                self.isLaunching = false
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("AetherBridge")
                try fm.createDirectory(at: supportDir, withIntermediateDirectories: true, attributes: nil)
                
                let destApp = supportDir.appendingPathComponent("Antigravity.app")
                
                // Compare modification dates
                let sourceAttrs = try fm.attributesOfItem(atPath: sourcePath)
                let sourceDate = sourceAttrs[.modificationDate] as? Date ?? Date.distantPast
                
                var needsCopy = true
                if fm.fileExists(atPath: destApp.path) {
                    let destAttrs = try fm.attributesOfItem(atPath: destApp.path)
                    let destDate = destAttrs[.modificationDate] as? Date ?? Date.distantPast
                    if destDate >= sourceDate {
                        needsCopy = false
                    } else {
                        try fm.removeItem(at: destApp)
                    }
                }
                
                if needsCopy {
                    DispatchQueue.main.async { self.statusMessage = "Cloning IDE..." }
                    try fm.copyItem(atPath: sourcePath, toPath: destApp.path)
                    
                    DispatchQueue.main.async { self.statusMessage = "Deep-Stripping signatures (takes ~10s)..." }
                    // Deep strip the signature across all helpers, node modules, and binaries
                    let stripTask = Process()
                    stripTask.executableURL = URL(fileURLWithPath: "/bin/bash")
                    stripTask.arguments = [
                        "-c",
                        "find '\(destApp.path)' -type f \\( -name \"*.dylib\" -o -name \"*.node\" -o -perm -0111 \\) -exec codesign --remove-signature {} 2>/dev/null \\; || true"
                    ]
                    try stripTask.run()
                    stripTask.waitUntilExit()
                }
                
                DispatchQueue.main.async { self.statusMessage = "Configuring proxychains..." }
                // Create proxychains.conf
                let confPath = supportDir.appendingPathComponent("proxychains.conf")
                let confContent = """
                strict_chain
                proxy_dns
                remote_dns_subnet 224
                tcp_read_time_out 15000
                tcp_connect_time_out 8000
                quiet_mode
                [ProxyList]
                socks5 127.0.0.1 \(self.proxyPort)
                """
                try confContent.write(to: confPath, atomically: true, encoding: .utf8)
                
                // Locate libproxychains4.dylib
                guard let bundleResourceURL = Bundle.main.resourceURL else {
                    throw NSError(domain: "AetherBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to find Resources"])
                }
                let dylibPath = bundleResourceURL.appendingPathComponent("libproxychains4.dylib").path
                
                if !fm.fileExists(atPath: dylibPath) {
                    throw NSError(domain: "AetherBridge", code: 2, userInfo: [NSLocalizedDescriptionKey: "libproxychains4.dylib not bundled!"])
                }
                
                // We use process to launch with DYLD_INSERT_LIBRARIES
                // NSWorkspace doesn't cleanly pass DYLD env vars on some newer macOS versions due to SIP
                // But since the app is stripped, Process() handles it flawlessly
                let executablePath = destApp.appendingPathComponent("Contents/MacOS/Electron").path
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                
                var env = ProcessInfo.processInfo.environment
                env["DYLD_INSERT_LIBRARIES"] = dylibPath
                env["PROXYCHAINS_CONF_FILE"] = confPath.path
                // Also retain Chromium hooks for good measure
                let socksProxy = "socks5://127.0.0.1:\(self.proxyPort)"
                env["HTTP_PROXY"] = "http://127.0.0.1:\(self.proxyPort)"
                process.environment = env
                process.arguments = [
                    "--proxy-server=\(socksProxy)",
                    "--host-resolver-rules=MAP * ~NOTFOUND , EXCLUDE 127.0.0.1",
                    "--disable-quic"
                ]
                
                try process.run()
                
                DispatchQueue.main.async {
                    self.statusMessage = "✅ Launched via Proxychains DYLD Hook!"
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
