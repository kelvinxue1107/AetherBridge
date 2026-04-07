#!/bin/bash
# Focused debug: test if Gemini endpoints work through SOCKS5
PORT="${1:-10808}"

echo "=== Testing specific Gemini API endpoints through SOCKS5 ==="
echo ""

echo "--- 1. google.com (baseline) ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT https://www.google.com -o /dev/null -w "Status: %{http_code}, Time: %{time_total}s\n"

echo "--- 2. cloudcode-pa.googleapis.com ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT https://cloudcode-pa.googleapis.com -o /dev/null -w "Status: %{http_code}, Time: %{time_total}s\n"

echo "--- 3. daily-cloudcode-pa.googleapis.com ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT https://daily-cloudcode-pa.googleapis.com -o /dev/null -w "Status: %{http_code}, Time: %{time_total}s\n"

echo "--- 4. antigravity-unleash.goog ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT https://antigravity-unleash.goog -o /dev/null -w "Status: %{http_code}, Time: %{time_total}s\n"

echo "--- 5. play.googleapis.com ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT https://play.googleapis.com -o /dev/null -w "Status: %{http_code}, Time: %{time_total}s\n"

echo "--- 6. www.googleapis.com ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT https://www.googleapis.com -o /dev/null -w "Status: %{http_code}, Time: %{time_total}s\n"

echo ""
echo "--- 7. Testing HTTP/2 streaming (gRPC-like) to cloudcode-pa ---"
curl -s --max-time 10 --socks5-hostname 127.0.0.1:$PORT --http2 -H "Content-Type: application/grpc" https://cloudcode-pa.googleapis.com -o /dev/null -w "Status: %{http_code}, HTTP ver: %{http_version}, Time: %{time_total}s\n"

echo ""
echo "--- 8. Testing HTTP proxy mode (not SOCKS5) ---"
curl -s --max-time 10 --proxy http://127.0.0.1:$PORT https://www.google.com -o /dev/null -w "Status: %{http_code}, Time: %{time_total}s\n"

echo ""
echo "--- 9. Launch stripped Electron with --proxy-server (15s test) ---"
ELECTRON="$HOME/Library/Application Support/AetherBridge/Antigravity.app/Contents/MacOS/Electron"
if [ -f "$ELECTRON" ]; then
    echo "Launching Electron with --proxy-server only..."
    "$ELECTRON" \
        --proxy-server="socks5://127.0.0.1:$PORT" \
        --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE 127.0.0.1" \
        --disable-quic &
    EPID=$!
    echo "Electron PID: $EPID"
    sleep 15
    echo "Killing Electron..."
    kill $EPID 2>/dev/null
    echo "(Check v2rayN logs for connections during those 15 seconds)"
else
    echo "❌ Stripped Electron not found"
fi

echo ""
echo "=== Debug complete ==="
