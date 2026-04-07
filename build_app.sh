#!/bin/bash
echo "Building proxychains-ng..."
export MACOSX_DEPLOYMENT_TARGET=13.0

if [ ! -f "proxychains-ng/libproxychains4.dylib" ]; then
    echo "Downloading and compiling proxychains-ng..."
    rm -rf proxychains-ng
    git clone https://github.com/rofl0r/proxychains-ng.git
    cd proxychains-ng
    ./configure
    make
    cd ..
fi

echo "Building AetherBridge..."
swift build -c release

echo "Creating macOS App Bundle..."
mkdir -p AetherBridge.app/Contents/MacOS
mkdir -p AetherBridge.app/Contents/Resources

# Copy the Swift binary
cp .build/apple/Products/Release/AetherBridge AetherBridge.app/Contents/MacOS/ 2>/dev/null || cp .build/release/AetherBridge AetherBridge.app/Contents/MacOS/

# Copy the pre-compiled proxychains library
cp proxychains-ng/libproxychains4.dylib AetherBridge.app/Contents/Resources/

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
    <string>3.0</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <!-- Hide the dock icon -->
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Done! You can now run AetherBridge.app"
