# AetherBridge ✨ (Seamless Launcher Edition)

**AetherBridge** is a native macOS Menu Bar launcher designed specifically for developers using the **Google Antigravity IDE** in regions with restricted network access. 

It acts as a secure proxy wrapper that automatically binds the Antigravity IDE traffic to your local VLESS/V2Ray proxies without requiring the system-wide TUN mode, and completely bypassing the need for complex DYLD Hooking or Terminal launches.

---

## 📥 Installation

1. **Download the Release:** Go to the [Releases page](https://github.com/kelvinxue1107/AetherBridge/releases) and download the `AetherBridge-v2.0.zip`.
2. **Extract the App:** Double-click the `.zip` file to extract `AetherBridge.app`.
3. **Move to Applications:** Drag `AetherBridge.app` into your macOS `Applications` folder.
4. **First Launch:** 
   - Right-click (or Control-click) on `AetherBridge.app` and select **Open**. 
   - Click **Open** again to bypass macOS Gatekeeper.

*(AetherBridge runs purely in your Menu Bar at the top right of your screen and has no Dock icon.)*

---

## 📖 User Manual

### Prerequisites
You must have a proxy application (e.g., v2rayU, ClashX, or Shadowrocket for Mac) actively running and connected to a VLESS node. You will need to know its local SOCKS5 or HTTP listening port (e.g., `10808`, `7890`, etc.).

### Step-by-Step Usage

Instead of opening the Antigravity IDE directly from your Dock, you will use AetherBridge as your secure Launcher!

1. **Locate the Icon:** Click the `link.icloud` icon in your macOS Menu Bar.
2. **Enter Proxy Port:** In the text field labeled **VLESS Port**, type the exact local port your proxy software uses (for example: `10808`).
3. **Launch Securely:** Click the **Launch Antigravity Securely** button.
   - *What happens under the hood:* AetherBridge dynamically bounds standard networking environment variables (`HTTP_PROXY`, `ALL_PROXY`, etc.) targeting your local VLESS port, and launches the native Antigravity IDE application cleanly in the background.
4. **Work Securely:** The Google Antigravity IDE will open normally! All its internal API requests will securely route through your proxy, while Safari and the rest of your Mac use the standard network!

---

## 🛠 Building from Source

If you prefer to compile AetherBridge yourself:

1. Clone this repository and checkout the launcher branch:
   ```bash
   git clone https://github.com/kelvinxue1107/AetherBridge.git
   cd AetherBridge
   git checkout dev/seamless-launcher
   ```
2. Run the packaging script:
   ```bash
   ./build_app.sh
   ```
3. Use the resulting compiled bundle:
   ```bash
   open AetherBridge.app
   ```
