#!/bin/bash
echo "Building AetherBridge..."
swift build -c release --arch arm64 --arch x86_64

echo "Creating minimal macOS App Bundle..."
mkdir -p AetherBridge.app/Contents/MacOS
cp .build/apple/Products/Release/AetherBridge AetherBridge.app/Contents/MacOS/ || cp .build/release/AetherBridge AetherBridge.app/Contents/MacOS/

cat <<EOF > AetherBridge.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AetherBridge</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.aetherbridge</string>
    <key>CFBundleName</key>
    <string>AetherBridge</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <!-- Hide the dock icon -->
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Done! You can now run AetherBridge.app"
