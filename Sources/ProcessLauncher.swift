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
        statusMessage = "Setting up secure clone..."
        
        let sourcePath = "/Applications/Antigravity.app"
        
        if !FileManager.default.fileExists(atPath: sourcePath) {
            statusMessage = "❌ Antigravity not found at /Applications/"
            isLaunching = false
            return
        }
        
        // Capture values for the background task
        let port = self.proxyPort
        
        Task.detached { [weak self] in
            do {
                let fm = FileManager.default
                let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("AetherBridge")
                try fm.createDirectory(at: supportDir, withIntermediateDirectories: true, attributes: nil)
                
                let destApp = supportDir.appendingPathComponent("Antigravity.app")
                
                // Compare modification dates to decide whether to re-clone
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
                    await MainActor.run { self?.statusMessage = "Cloning IDE (~30s first time)..." }
                    try fm.copyItem(atPath: sourcePath, toPath: destApp.path)
                    
                    await MainActor.run { self?.statusMessage = "Deep-stripping signatures (~20s)..." }
                    let stripTask = Process()
                    stripTask.executableURL = URL(fileURLWithPath: "/bin/bash")
                    stripTask.arguments = [
                        "-c",
                        "find '\(destApp.path)' -type f \\( -name \"*.dylib\" -o -name \"*.node\" -o -name \"*.so\" -o -perm +0111 \\) -exec codesign --remove-signature {} 2>/dev/null \\; ; codesign --remove-signature '\(destApp.path)' 2>/dev/null; exit 0"
                    ]
                    try stripTask.run()
                    stripTask.waitUntilExit()
                }
                
                await MainActor.run { self?.statusMessage = "Writing proxychains config..." }
                
                // Write proxychains.conf (no leading whitespace!)
                let confPath = supportDir.appendingPathComponent("proxychains.conf")
                let confLines = [
                    "strict_chain",
                    "proxy_dns",
                    "remote_dns_subnet 198",
                    "tcp_read_time_out 1500000",
                    "tcp_connect_time_out 15000",
                    "quiet_mode",
                    "[ProxyList]",
                    "socks5 127.0.0.1 \(port)"
                ]
                let confContent = confLines.joined(separator: "\n") + "\n"
                try confContent.write(to: confPath, atomically: true, encoding: .utf8)
                
                // Locate the bundled proxychains4 binary and dylib
                guard let bundleResourceURL = Bundle.main.resourceURL else {
                    throw NSError(domain: "AetherBridge", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to find app Resources"])
                }
                
                let pc4Path = bundleResourceURL.appendingPathComponent("proxychains4").path
                let dylibPath = bundleResourceURL.appendingPathComponent("libproxychains4.dylib").path
                
                let electronPath = destApp.appendingPathComponent("Contents/MacOS/Electron").path
                
                if !fm.fileExists(atPath: electronPath) {
                    throw NSError(domain: "AetherBridge", code: 3,
                                  userInfo: [NSLocalizedDescriptionKey: "Electron binary not found in clone"])
                }
                
                await MainActor.run { self?.statusMessage = "Launching via proxychains..." }
                
                if fm.fileExists(atPath: pc4Path) {
                    // Preferred: Use proxychains4 binary as wrapper
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: pc4Path)
                    process.arguments = ["-f", confPath.path, electronPath]
                    
                    var env = ProcessInfo.processInfo.environment
                    env["PROXYCHAINS_CONF_FILE"] = confPath.path
                    // Remove any system proxy settings that could conflict
                    env.removeValue(forKey: "http_proxy")
                    env.removeValue(forKey: "https_proxy")
                    env.removeValue(forKey: "HTTP_PROXY")
                    env.removeValue(forKey: "HTTPS_PROXY")
                    env.removeValue(forKey: "ALL_PROXY")
                    process.environment = env
                    
                    try process.run()
                    
                    await MainActor.run {
                        self?.statusMessage = "✅ Launched via proxychains4 wrapper!"
                        self?.isLaunching = false
                    }
                } else if fm.fileExists(atPath: dylibPath) {
                    // Fallback: Use DYLD_INSERT_LIBRARIES directly
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: electronPath)
                    
                    var env = ProcessInfo.processInfo.environment
                    env["DYLD_INSERT_LIBRARIES"] = dylibPath
                    env["PROXYCHAINS_CONF_FILE"] = confPath.path
                    env.removeValue(forKey: "http_proxy")
                    env.removeValue(forKey: "https_proxy")
                    env.removeValue(forKey: "HTTP_PROXY")
                    env.removeValue(forKey: "HTTPS_PROXY")
                    env.removeValue(forKey: "ALL_PROXY")
                    process.environment = env
                    
                    try process.run()
                    
                    await MainActor.run {
                        self?.statusMessage = "✅ Launched via DYLD injection!"
                        self?.isLaunching = false
                    }
                } else {
                    throw NSError(domain: "AetherBridge", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: "Neither proxychains4 nor dylib found in bundle!"])
                }
                
            } catch {
                await MainActor.run {
                    self?.statusMessage = "❌ Error: \(error.localizedDescription)"
                    self?.isLaunching = false
                }
            }
        }
    }
}
