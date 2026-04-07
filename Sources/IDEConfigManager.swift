import Foundation
import Combine

class IDEConfigManager: ObservableObject {
    @Published var proxyPort: String = "10808" {
        didSet {
            // Un-set if toggled and port changes
            if isProxyEnabled {
                applyProxy()
            }
        }
    }
    
    @Published var isProxyEnabled: Bool = false {
        didSet {
            if isProxyEnabled {
                applyProxy()
            } else {
                removeProxy()
            }
        }
    }
    
    private var configPath: URL {
        let homeUrl = FileManager.default.homeDirectoryForCurrentUser
        return homeUrl.appendingPathComponent(".antigravity/settings.json")
    }
    
    init() {
        // Load initial state based on file existence and contents
        if FileManager.default.fileExists(atPath: configPath.path) {
            do {
                let data = try Data(contentsOf: configPath)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let proxyStr = json["http.proxy"] as? String {
                    self.isProxyEnabled = true
                    // Extract port
                    if let portRange = proxyStr.range(of: ":", options: .backwards) {
                        self.proxyPort = String(proxyStr[portRange.upperBound...])
                    }
                }
            } catch {
                print("Failed to read settings.json: \(error)")
            }
        }
    }
    
    private func applyProxy() {
        var json: [String: Any] = [:]
        
        let pUrl = configPath
        
        do {
            if FileManager.default.fileExists(atPath: pUrl.path) {
                let data = try Data(contentsOf: pUrl)
                if let existingJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    json = existingJson
                }
            } else {
                // Try to create directory
                let dir = pUrl.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Assuming the proxy config key is http.proxy
            json["http.proxy"] = "http://127.0.0.1:\(proxyPort)"
            json["http.proxyStrictSSL"] = false // commonly needed
            
            let outputData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try outputData.write(to: pUrl)
            print("Proxy enabled at 127.0.0.1:\(proxyPort)")
        } catch {
            print("Failed to write to settings.json: \(error)")
        }
    }
    
    private func removeProxy() {
        let pUrl = configPath
        guard FileManager.default.fileExists(atPath: pUrl.path) else { return }
        
        do {
            let data = try Data(contentsOf: pUrl)
            guard var json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
            
            json.removeValue(forKey: "http.proxy")
            json.removeValue(forKey: "http.proxyStrictSSL")
            
            let outputData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try outputData.write(to: pUrl)
            print("Proxy disabled")
        } catch {
            print("Failed to remove proxy from settings.json: \(error)")
        }
    }
}
