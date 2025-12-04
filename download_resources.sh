#!/bin/bash

# Download external resources for the captive portal
# This script downloads CSS and images from the real UNI-MAINZ server

echo "============================================================"
echo "UNI-MAINZ Captive Portal - Resource Downloader"
echo "============================================================"
echo ""

# Create directories
mkdir -p css
mkdir -p images

# Download CSS
echo "Downloading CSS..."
curl -s -o css/style.css "https://login.uni-mainz.de/adfs/portal/css/style.css?id=26CEECBE647EF7ACA381009BB3CF2F032EEADC53BBB43F89F64DC261F1124717"
if [ $? -eq 0 ]; then
    echo "  ✓ Downloaded css/style.css"
else
    echo "  ✗ Failed to download CSS"
fi

# Download illustration
echo "Downloading illustration..."
curl -s -o images/illustration.png "https://login.uni-mainz.de/adfs/portal/illustration/illustration.png?id=6F3C65EF5615D6F0246C7044E94ACE44FD9213A094B2C7BA701F733D1550D3BC"
if [ $? -eq 0 ]; then
    echo "  ✓ Downloaded images/illustration.png"
else
    echo "  ✗ Failed to download illustration"
fi

# Download logo
echo "Downloading logo..."
curl -s -o images/logo.png "https://login.uni-mainz.de/adfs/portal/logo/logo.png?id=F7B50A47667D7645693BC41BDBEBF8EB500223E44756E685F7F08ADB1D1898DB"
if [ $? -eq 0 ]; then
    echo "  ✓ Downloaded images/logo.png"
else
    echo "  ✗ Failed to download logo"
fi

# Download localsts icon
echo "Downloading localsts icon..."
curl -s -o images/localsts.png "https://login.uni-mainz.de/adfs/portal/images/idp/localsts.png?id=813E4C443F9CC910A75A0A34D88125C8D8BB17EC310BFC99768CB28F1A066C5E"
if [ $? -eq 0 ]; then
    echo "  ✓ Downloaded images/localsts.png"
else
    echo "  ✗ Failed to download localsts icon"
fi

# Download idp icon
echo "Downloading idp icon..."
curl -s -o images/idp.png "https://login.uni-mainz.de/adfs/portal/images/idp/idp.png?id=BA97FED77919F4CEF84BEE47CFAFA5E1236B77099F25320730C09B7B6CA21F3C"
if [ $? -eq 0 ]; then
    echo "  ✓ Downloaded images/idp.png"
else
    echo "  ✗ Failed to download idp icon"
fi

echo ""
echo "Updating index.html to use local resources..."

# Backup original
cp index.html index.html.backup

# Update CSS link
sed -i.tmp 's|href="https://login\.uni-mainz\.de/adfs/portal/css/style\.css[^"]*"|href="/css/style.css"|g' index.html

# Update illustration URL
sed -i.tmp 's|url(https://login\.uni-mainz\.de/adfs/portal/illustration/illustration\.png[^)]*)|url(/images/illustration.png)|g' index.html

# Update logo src
sed -i.tmp "s|src='https://login\.uni-mainz\.de/adfs/portal/logo/logo\.png[^']*'|src='/images/logo.png'|g" index.html

# Update localsts.png
sed -i.tmp "s|src=\"https://login\.uni-mainz\.de/adfs/portal/images/idp/localsts\.png[^\"]*\"|src=\"/images/localsts.png\"|g" index.html

# Update idp.png
sed -i.tmp "s|src=\"https://login\.uni-mainz\.de/adfs/portal/images/idp/idp\.png[^\"]*\"|src=\"/images/idp.png\"|g" index.html

# Remove temp files
rm -f index.html.tmp

echo "  ✓ Updated index.html"
echo ""
echo "✓ All done! The captive portal is now self-contained."
echo "  External resources have been downloaded and HTML updated."
echo "  Original HTML backed up to index.html.backup"
