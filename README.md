# AetherBridge ✨

**AetherBridge** is a native macOS Menu Bar utility designed specifically for developers using the **Google Antigravity IDE** in regions with restricted network access. 

It acts as a configuration bridge that seamlessly routes *only* your Antigravity IDE traffic through your existing local VLESS/V2Ray proxies (like v2rayU or ClashX) without forcing your entire Mac into a system-wide TUN routing mode.

---

## 📥 Installation

1. **Download the Release:** Go to the [Releases page](https://github.com/kelvinxue1107/AetherBridge/releases) and download the latest `AetherBridge-v1.0.zip`.
2. **Extract the App:** Double-click the `.zip` file to extract `AetherBridge.app`.
3. **Move to Applications:** Drag `AetherBridge.app` into your macOS `Applications` folder.
4. **First Launch:** 
   *(Note: Because this app is not signed with an Apple Developer ID yet, macOS Gatekeeper might block it initially.)*
   - Right-click (or Control-click) on `AetherBridge.app` and select **Open**. 
   - A warning will appear. Click **Open** again to bypass Gatekeeper.

*(AetherBridge runs purely in your Menu Bar at the top right of your screen and has no Dock icon.)*

---

## 📖 User Manual

### Prerequisites
You must have a proxy application (e.g., v2rayU, ClashX, or Shadowrocket for Mac) actively running and connected to a VLESS node. You will need to know its local SOCKS5 or HTTP listening port (e.g., `10808`, `7890`, etc.).

### Step-by-Step Usage

1. **Locate the Icon:** Click the `link.icloud` icon in your macOS Menu Bar.
2. **Enter Proxy Port:** In the text field labeled **Proxy Port**, type the exact local port your proxy software uses (for example: `10808`).
3. **Toggle the Switch:** Click the **Enable IDE Proxy** switch so it turns blue.
   - *What happens under the hood:* AetherBridge safely injects the local proxy settings directly into the Antigravity IDE's `settings.json` file.
4. **Work Securely:** Open the Google Antigravity IDE. All its API requests will now route through your proxy seamlessly, while Safari and the rest of your Mac use the standard network!
5. **Disable when done:** If you want to disable the forwarding, simply toggle the switch off.

---

## 🛠 Building from Source

If you prefer to compile AetherBridge yourself:

1. Clone this repository:
   ```bash
   git clone https://github.com/kelvinxue1107/AetherBridge.git
   cd AetherBridge
   ```
2. Run the packaging script:
   ```bash
   ./build_app.sh
   ```
3. Use the resulting compiled bundle:
   ```bash
   open AetherBridge.app
   ```
