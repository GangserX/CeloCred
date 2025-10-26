# Assets Directory

This folder contains all images and resources for the CeloCred app.

## 📁 Folder Structure

### `logo/`
**Purpose:** Put your app logo here
- Use this for the app icon and branding
- Recommended formats: PNG (with transparency) or SVG
- Recommended sizes:
  - App icon: 1024x1024 pixels
  - Logo for app: 512x512 pixels or higher
  - Transparent background recommended

**Example files you can add:**
- `app_logo.png` - Main logo
- `app_icon.png` - App icon
- `logo_white.png` - White version for dark backgrounds
- `logo_colored.png` - Colored version for light backgrounds

### `images/`
**Purpose:** General images used in the app
- Icons, illustrations, graphics
- Background images
- Button graphics
- Any other visual elements

**Example files you can add:**
- `wallet_icon.png`
- `payment_success.png`
- `background_pattern.png`
- etc.

### `ui_reference/`
**Purpose:** UI design reference images
- Put your UI mockups here
- Design screenshots
- Reference images for how screens should look
- These are for development reference only (won't be included in final app)

**Example files you can add:**
- `home_screen_design.png`
- `payment_screen_design.jpg`
- `wallet_ui_mockup.png`
- `complete_app_design.pdf`
- etc.

## 🎨 How to Use

### Adding Your Logo
1. Put your logo image in `assets/logo/` folder
2. In your Dart code, use it like this:
```dart
Image.asset('assets/logo/app_logo.png')
```

### Adding UI Reference Images
1. Put design mockups in `assets/ui_reference/` folder
2. I can see them and build screens based on your designs
3. Just tell me "Check the UI reference for the home screen"

## 📝 Supported Formats
- PNG (recommended for logos with transparency)
- JPG/JPEG (for photos and backgrounds)
- SVG (vector graphics - needs flutter_svg package)
- GIF (animations)
- WebP (modern format)

## 💡 Tips
- Use PNG for logos (supports transparency)
- Use JPG for photos (smaller file size)
- Keep file sizes reasonable (< 1MB per image)
- Use descriptive names (e.g., `home_screen_hero.png` instead of `img1.png`)
