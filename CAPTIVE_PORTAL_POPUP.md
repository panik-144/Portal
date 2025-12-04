# Captive Portal Auto-Popup Guide

## How It Works
For a captive portal to pop up automatically on a victim's device (iPhone, Android, Windows), the following chain of events must happen:

1.  **Connection**: Victim connects to the Wi-Fi ("UNI-MAINZ").
2.  **Detection**: The OS immediately tries to connect to a specific "test" URL to check for internet access.
    *   **iOS**: `http://captive.apple.com/hotspot-detect.html`
    *   **Android**: `http://connectivitycheck.gstatic.com/generate_204`
    *   **Windows**: `http://www.msftconnecttest.com/connecttest.txt`
3.  **Interception**:
    *   **DNS**: `dnsmasq` resolves these domains to your gateway IP (`192.168.10.1`).
    *   **Firewall**: `iptables` redirects the HTTP request (port 80) to your Flask app (port 8080).
4.  **Response**:
    *   Your Flask app receives the request (e.g., `GET /hotspot-detect.html`).
    *   **CRITICAL**: Instead of 404, it must return a **redirect (302)** or the login page itself.
5.  **Trigger**: The OS sees it didn't get the expected "Success" message and assumes it's behind a captive portal. It then launches the mini-browser with your page.

## What We Fixed
We updated `app.py` to ensure this chain works perfectly:

1.  **Catch-All Route**: Added a wildcard route `/<path:path>` that catches *any* URL request.
2.  **Forced Redirect**: Any request to these test URLs now returns a `302 Found` redirect to your login page.
3.  **No Caching**: Added headers to prevent the device from remembering "I'm offline" or "I'm online", forcing the check every time.

## Troubleshooting the Popup

If the popup **still** doesn't appear:

### 1. Forget the Network
Devices cache network states aggressively.
*   **Action**: On the victim device, go to Wi-Fi settings, select "UNI-MAINZ", and tap **"Forget This Network"**. Then reconnect.

### 2. Check DNS Spoofing
Ensure `dnsmasq` is actually resolving everything to your IP.
*   **Test**: On the rogue AP machine, run:
    ```bash
    dig google.com @localhost
    ```
    *Result*: Should return `192.168.10.1`.

### 3. Check iptables Redirection
Ensure traffic is hitting your Flask app.
*   **Test**: Watch the Flask logs while a device connects.
    ```bash
    tail -f flask.log
    ```
    *Result*: You should see requests for `generate_204` or `hotspot-detect.html`.

### 4. HTTPS Issues
Modern devices try HTTPS checks too. Since we can't fake the SSL certificate for `google.com` or `apple.com`, these connections will fail (SSL Error).
*   **Note**: This is normal. The device will usually fall back to HTTP to check for a captive portal.
*   **Impact**: The browser might show a security warning if the user manually types `https://google.com`. This is unavoidable without a trusted CA certificate installed on the victim's device.

## Testing the Popup
1.  Connect a phone to "UNI-MAINZ".
2.  Wait 3-5 seconds.
3.  The "Log In" or "Sign In" screen should slide up automatically.
4.  If not, open a browser and type `http://neverssl.com` (a site that forces HTTP). It should redirect to your login page immediately.
