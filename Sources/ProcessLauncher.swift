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
        
        let port = self.proxyPort
        
        Task.detached {
            do {
                let fm = FileManager.default
                let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("AetherBridge")
                try fm.createDirectory(at: supportDir, withIntermediateDirectories: true, attributes: nil)
                
                let destApp = supportDir.appendingPathComponent("Antigravity.app")
                
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
                
                // Write a helper shell script that launches the app with environment
                // Using 'open' command ensures the .app bundle is loaded correctly
                await MainActor.run { self.statusMessage = "Launching Antigravity..." }
                
                let httpProxy = "http://127.0.0.1:\(port)"
                let socksProxy = "socks5://127.0.0.1:\(port)"
                let launchScript = supportDir.appendingPathComponent("launch.sh")
                
                let scriptContent = """
                #!/bin/bash
                export HTTP_PROXY="\(httpProxy)"
                export HTTPS_PROXY="\(httpProxy)"
                export ALL_PROXY="\(socksProxy)"
                export http_proxy="\(httpProxy)"
                export https_proxy="\(httpProxy)"
                export all_proxy="\(socksProxy)"
                export GLOBAL_AGENT_HTTP_PROXY="\(httpProxy)"
                export GLOBAL_AGENT_HTTPS_PROXY="\(httpProxy)"
                export GLOBAL_AGENT_NO_PROXY="localhost,127.0.0.1,::1"
                export NO_PROXY="localhost,127.0.0.1,::1"
                export no_proxy="localhost,127.0.0.1,::1"
                export grpc_proxy="\(httpProxy)"
                export NODE_TLS_REJECT_UNAUTHORIZED="0"
                
                # Launch Electron directly from correct working directory
                cd "\(destApp.appendingPathComponent("Contents/MacOS").path)"
                exec ./Electron \\
                    --proxy-server="http://127.0.0.1:\(port)" \\
                    --disable-quic \\
                    "$@"
                """
                
                try scriptContent.write(to: launchScript, atomically: true, encoding: .utf8)
                
                // Make executable
                let chmodTask = Process()
                chmodTask.executableURL = URL(fileURLWithPath: "/bin/chmod")
                chmodTask.arguments = ["+x", launchScript.path]
                try chmodTask.run()
                chmodTask.waitUntilExit()
                
                // Launch the script
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = [launchScript.path]
                
                // Capture stderr for debugging
                let errPipe = Pipe()
                process.standardError = errPipe
                
                try process.run()
                
                // Read first few seconds of stderr for any crash info
                DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                    let errData = errPipe.fileHandleForReading.availableData
                    if let errStr = String(data: errData, encoding: .utf8), !errStr.isEmpty {
                        let preview = String(errStr.prefix(200))
                        Task { @MainActor in
                            self.statusMessage = "⚠️ Stderr: \(preview)"
                        }
                    }
                }
                
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
