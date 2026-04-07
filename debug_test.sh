#!/bin/bash
# AetherBridge Debug Script
# Run with: bash debug_test.sh
# IMPORTANT: Run this with TUN mode OFF and v2rayN running in normal mode

PORT="${1:-10808}"
SUPPORT_DIR="$HOME/Library/Application Support/AetherBridge"
CLONED_APP="$SUPPORT_DIR/Antigravity.app"
ELECTRON="$CLONED_APP/Contents/MacOS/Electron"
DYLIB="$HOME/Documents/AetherBridge/AetherBridge.app/Contents/Resources/libproxychains4.dylib"
CONF="$SUPPORT_DIR/proxychains.conf"
PC4="$HOME/Documents/AetherBridge/proxychains-ng/proxychains4"

echo "========================================"
echo "AetherBridge Debug v1.0"
echo "========================================"
echo "Proxy port: $PORT"
echo ""

# Test 1: Is v2rayN listening?
echo "--- TEST 1: Proxy port check ---"
lsof -nP -iTCP:$PORT -sTCP:LISTEN 2>/dev/null | head -5
if [ $? -ne 0 ]; then
    echo "⚠️  Nothing listening on port $PORT!"
fi
echo ""

# Test 2: Can we connect through the proxy directly?
echo "--- TEST 2: Direct SOCKS5 proxy test (curl) ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT https://www.google.com -o /dev/null -w "HTTP Status: %{http_code}, Time: %{time_total}s\n"
echo ""

# Test 3: Check if cloned app exists and is stripped
echo "--- TEST 3: Cloned app check ---"
if [ -d "$CLONED_APP" ]; then
    echo "✅ Cloned app exists"
    codesign -dv "$ELECTRON" 2>&1 | head -3
else
    echo "❌ Cloned app NOT found"
fi
echo ""

# Test 4: Check proxychains.conf content
echo "--- TEST 4: proxychains.conf content ---"
if [ -f "$CONF" ]; then
    cat "$CONF"
else
    echo "❌ proxychains.conf NOT found"
fi
echo ""

# Test 5: Check if dylib exists
echo "--- TEST 5: libproxychains4.dylib check ---"
if [ -f "$DYLIB" ]; then
    echo "✅ dylib exists at: $DYLIB"
    file "$DYLIB"
else
    echo "❌ dylib NOT found"
fi
echo ""

# Test 6: Test proxychains with curl (DYLD method)
echo "--- TEST 6: Proxychains DYLD + curl test ---"
DYLD_INSERT_LIBRARIES="$DYLIB" PROXYCHAINS_CONF_FILE="$CONF" curl -s --max-time 10 https://www.google.com -o /dev/null -w "HTTP Status: %{http_code}, Time: %{time_total}s\n" 2>&1
echo ""

# Test 7: Test proxychains4 binary wrapper (if available)
echo "--- TEST 7: proxychains4 binary wrapper test ---"
if [ -x "$PC4" ]; then
    echo "✅ proxychains4 binary exists"
    PROXYCHAINS_CONF_FILE="$CONF" "$PC4" -f "$CONF" curl -s --max-time 10 https://www.google.com -o /dev/null -w "HTTP Status: %{http_code}, Time: %{time_total}s\n" 2>&1
else
    echo "⚠️  proxychains4 binary NOT found at $PC4"
fi
echo ""

# Test 8: Test Electron launch with ONLY --proxy-server (no DYLD)
echo "--- TEST 8: Launch test with ONLY --proxy-server flag (10s) ---"
echo "(Starting Electron with just --proxy-server, capturing stderr for 10s...)"
timeout 10 "$ELECTRON" \
    --proxy-server="socks5://127.0.0.1:$PORT" \
    --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE 127.0.0.1" \
    --disable-quic 2>&1 | grep -iE "error|proxy|fail|socks|connect" | head -20
echo "(Test 8 finished)"
echo ""

# Test 9: Test Electron launch with ONLY DYLD proxychains (no --proxy-server)
echo "--- TEST 9: Launch test with ONLY DYLD proxychains (10s) ---"
echo "(Starting Electron with just DYLD_INSERT_LIBRARIES, capturing stderr for 10s...)"
timeout 10 env \
    DYLD_INSERT_LIBRARIES="$DYLIB" \
    PROXYCHAINS_CONF_FILE="$CONF" \
    "$ELECTRON" 2>&1 | grep -iE "error|proxy|fail|socks|connect|proxychains|dyld" | head -20
echo "(Test 9 finished)"
echo ""

echo "========================================"
echo "Debug complete! Please copy ALL output above and share it."
echo "========================================"
