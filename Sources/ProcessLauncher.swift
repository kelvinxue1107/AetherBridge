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
        statusMessage = "Setting up..."
        
        let sourcePath = "/Applications/Antigravity.app"
        
        if !FileManager.default.fileExists(atPath: sourcePath) {
            statusMessage = "❌ Antigravity not found at /Applications/"
            isLaunching = false
            return
        }
        
        // Capture port for background work
        let port = self.proxyPort
        
        Task.detached {
            do {
                let fm = FileManager.default
                let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("AetherBridge")
                try fm.createDirectory(at: supportDir, withIntermediateDirectories: true, attributes: nil)
                
                let destApp = supportDir.appendingPathComponent("Antigravity.app")
                
                // Check if we need to re-clone
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
                    await MainActor.run { self.statusMessage = "Cloning IDE (~30s first time)..." }
                    try fm.copyItem(atPath: sourcePath, toPath: destApp.path)
                    
                    await MainActor.run { self.statusMessage = "Stripping signatures (~20s)..." }
                    let stripTask = Process()
                    stripTask.executableURL = URL(fileURLWithPath: "/bin/bash")
                    stripTask.arguments = [
                        "-c",
                        "find '\(destApp.path)' -type f \\( -name \"*.dylib\" -o -name \"*.node\" -o -name \"*.so\" -o -perm +0111 \\) -exec codesign --remove-signature {} 2>/dev/null \\; ; codesign --remove-signature '\(destApp.path)' 2>/dev/null; exit 0"
                    ]
                    try stripTask.run()
                    stripTask.waitUntilExit()
                }
                
                let electronPath = destApp.appendingPathComponent("Contents/MacOS/Electron").path
                
                if !fm.fileExists(atPath: electronPath) {
                    throw NSError(domain: "AetherBridge", code: 3,
                                  userInfo: [NSLocalizedDescriptionKey: "Electron binary not found in clone"])
                }
                
                await MainActor.run { self.statusMessage = "Launching Antigravity..." }
                
                // Launch the stripped Electron with Chromium proxy flags + Node.js env vars
                let process = Process()
                process.executableURL = URL(fileURLWithPath: electronPath)
                
                // Chromium flags: force ALL network through SOCKS5 proxy
                process.arguments = [
                    "--proxy-server=socks5://127.0.0.1:\(port)",
                    "--disable-quic"
                ]
                
                // Environment: catch Node.js/gRPC traffic that bypasses Chromium net stack
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
                env["GLOBAL_AGENT_NO_PROXY"] = "localhost,127.0.0.1,::1"
                env["NO_PROXY"] = "localhost,127.0.0.1,::1"
                env["no_proxy"] = "localhost,127.0.0.1,::1"
                env["grpc_proxy"] = httpProxy
                env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0"
                process.environment = env
                
                try process.run()
                
                await MainActor.run {
                    self.statusMessage = "✅ Antigravity launched with proxy on port \(port)!"
                    self.isLaunching = false
                }
                
            } catch {
                await MainActor.run {
                    self.statusMessage = "❌ Error: \(error.localizedDescription)"
                    self.isLaunching = false
                }
            }
        }
    }
}
