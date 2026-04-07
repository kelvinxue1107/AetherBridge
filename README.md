# AetherBridge

AetherBridge is a native macOS companion tool designed specifically for the Google Antigravity IDE. It provides a seamless, targeted proxy bridge for Antigravity IDE to access Google API services in network-restricted regions (such as China) without the need to activate system-wide TUN mode.

## Features

- **Targeted Proxying:** Proxies only the network traffic from Antigravity IDE, leaving the rest of your system network transparent and unaffected.
- **VLESS & V2RayN Compatible:** Seamlessly integrates with local V2RayN/VLESS setups that are commonly used to bypass restrictive firewalls.
- **No TUN Mode Required:** Say goodbye to global routing conflicts. AetherBridge acts as a local interceptor/forwarder specific to API URLs used by the IDE.
- **macOS Native:** Built for macOS environments, providing a lightweight, low-resource background process.

## Getting Started

*(Development in Progress)*

### Prerequisites

- macOS 12+ 
- A working local V2Ray/vless client (e.g., v2rayN running via crossover, v2rayU, or command line v2ray core) exposing a local SOCKS5/HTTP port.
- Google Antigravity IDE installed.

### Setup

Currently in early development. Stay tuned for installation instructions.
