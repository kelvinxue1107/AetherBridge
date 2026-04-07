#!/bin/bash
set -e

echo "=== Step 1: Building proxychains-ng ==="
export MACOSX_DEPLOYMENT_TARGET=13.0

if [ ! -f "proxychains-ng/libproxychains4.dylib" ] || [ ! -f "proxychains-ng/proxychains4" ]; then
    echo "Downloading and compiling proxychains-ng..."
    rm -rf proxychains-ng
    git clone https://github.com/rofl0r/proxychains-ng.git
    cd proxychains-ng
    ./configure
    make
    cd ..
fi

echo "=== Step 2: Building AetherBridge Swift binary ==="
swift build -c release

echo "=== Step 3: Creating macOS App Bundle ==="
rm -rf AetherBridge.app
mkdir -p AetherBridge.app/Contents/MacOS
mkdir -p AetherBridge.app/Contents/Resources

# Copy the Swift binary
cp .build/apple/Products/Release/AetherBridge AetherBridge.app/Contents/MacOS/ 2>/dev/null || cp .build/release/AetherBridge AetherBridge.app/Contents/MacOS/

# Copy BOTH proxychains artifacts
cp proxychains-ng/libproxychains4.dylib AetherBridge.app/Contents/Resources/
cp proxychains-ng/proxychains4 AetherBridge.app/Contents/Resources/
chmod +x AetherBridge.app/Contents/Resources/proxychains4

if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns AetherBridge.app/Contents/Resources/
fi

cat <<EOF > AetherBridge.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AetherBridge</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.aetherbridge</string>
    <key>CFBundleName</key>
    <string>AetherBridge</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>4.0</string>
    <key>CFBundleVersion</key>
    <string>4</string>
    <!-- Hide the dock icon -->
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "=== Verifying bundle contents ==="
ls -la AetherBridge.app/Contents/Resources/
echo ""
echo "Done! AetherBridge.app is ready."
