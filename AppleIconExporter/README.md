# Apple Icon Exporter

An AppleScript tool to generate iOS and macOS app icon assets from a single source image.

## Requirements

- macOS
- A square image (1024x1024 or larger recommended)

## Usage

1. Open `IconExporter.applescript` in Script Editor (located in `/Applications/Utilities`)
2. Click **Compile** (Cmd+K) to check for errors
3. Click **Run** (Cmd+R) to execute, or **Export as Application** (Cmd+Shift+E) to create a standalone app
4. Select a square image (1024x1024 or larger) from the file picker
5. Icon assets will be exported to your Desktop

## Output Structure

The script creates a folder named `{ImageName} Icons` on your Desktop with the following structure:

```
{ImageName} Icons/
├── iOS/
│   ├── Contents.json
│   ├── icon_20x20.png, @2x, @3x
│   ├── icon_29x29.png, @2x, @3x
│   ├── icon_40x40.png, @2x, @3x
│   ├── icon_60x60.png, @2x, @3x
│   ├── icon_76x76.png, @2x
│   ├── icon_83.5x83.5@2x.png
│   └── icon_1024x1024.png
│
└── macOS/
    ├── Contents.json
    ├── icon_16x16.png, @2x
    ├── icon_32x32.png, @2x
    ├── icon_128x128.png, @2x
    ├── icon_256x256.png, @2x
    └── icon_512x512.png, @2x
```

## How to Use in Xcode

### For iOS App Icons

1. Open your project in Xcode
2. Select `Assets.xcassets` in the Project Navigator
3. Right-click and select **New App Icon Set**
4. Name it `AppIcon`
5. Copy all files from the `iOS/` folder into `AppIcon.appiconset/`
6. The `Contents.json` file is already included

### For macOS App Icons

1. Open your project in Xcode
2. Select `Assets.xcassets` in the Project Navigator
3. Right-click and select **New App Icon Set**
4. Name it `AppIcon`
5. Copy all files from the `macOS/` folder into `AppIcon.appiconset/`
6. The `Contents.json` file is already included

## Files

- `IconExporter.applescript` - Main script
- `iOS Contents.json` - iOS asset catalog template
- `macOS Contents.json` - macOS asset catalog template
- `README.md` - This file
