-- Icon Exporter
-- Select a square image (1024+) to generate MacOS/iOS icon assets to Desktop

-- Open file picker dialog
set sourceImage to choose file with prompt "Select a square image (1024x1024 or larger):" of type {"png", "jpeg", "jpg", "tiff", "heic"}
set sourcePath to POSIX path of sourceImage

-- Get image filename for folder name
set sourceName to do shell script "basename " & quoted form of sourcePath & " | sed 's/\\.[^.]*$//'"
set outputFolderName to sourceName & " Icons"

-- Get desktop path
tell application "System Events"
	set desktopPath to path to desktop folder
end tell
set desktopPosixPath to POSIX path of desktopPath

-- Create base folder containing iOS and macOS folders
set baseFolder to desktopPosixPath & outputFolderName
set iOSFolder to baseFolder & "/iOS"
set macOSFolder to baseFolder & "/macOS"
do shell script "mkdir -p " & quoted form of iOSFolder
do shell script "mkdir -p " & quoted form of macOSFolder

-- Export iOS icons
-- 20pt
do shell script "sips -z 40 40 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_20x20.png"
do shell script "sips -z 60 60 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_20x20@2x.png"
do shell script "sips -z 60 60 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_20x20@3x.png"

-- 29pt
do shell script "sips -z 58 58 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_29x29.png"
do shell script "sips -z 58 58 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_29x29@2x.png"
do shell script "sips -z 87 87 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_29x29@3x.png"

-- 40pt
do shell script "sips -z 80 80 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_40x40.png"
do shell script "sips -z 80 80 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_40x40@2x.png"
do shell script "sips -z 120 120 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_40x40@3x.png"

-- 60pt
do shell script "sips -z 120 120 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_60x60.png"
do shell script "sips -z 120 120 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_60x60@2x.png"
do shell script "sips -z 180 180 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_60x60@3x.png"

-- iPad 76pt
do shell script "sips -z 76 76 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_76x76.png"
do shell script "sips -z 152 152 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_76x76@2x.png"

-- iPad 83.5pt
do shell script "sips -z 167 167 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_83.5x83.5@2x.png"

-- iOS Marketing (1024pt)
do shell script "sips -z 1024 1024 " & quoted form of sourcePath & " --out " & quoted form of iOSFolder & "/icon_1024x1024.png"

-- Copy iOS Contents.json
set iOSTemplatePath to "/Users/caishilin/Desktop/personal/Scripts/AppleIconExporter/iOS Contents.json"
set iOSJsonDest to iOSFolder & "/Contents.json"
do shell script "cp " & quoted form of iOSTemplatePath & " " & quoted form of iOSJsonDest

-- Export macOS icons
-- 16pt
do shell script "sips -z 16 16 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_16x16.png"
do shell script "sips -z 32 32 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_16x16@2x.png"

-- 32pt
do shell script "sips -z 32 32 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_32x32.png"
do shell script "sips -z 64 64 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_32x32@2x.png"

-- 128pt
do shell script "sips -z 128 128 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_128x128.png"
do shell script "sips -z 256 256 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_128x128@2x.png"

-- 256pt
do shell script "sips -z 256 256 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_256x256.png"
do shell script "sips -z 512 512 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_256x256@2x.png"

-- 512pt
do shell script "sips -z 512 512 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_512x512.png"
do shell script "sips -z 1024 1024 " & quoted form of sourcePath & " --out " & quoted form of macOSFolder & "/icon_512x512@2x.png"

-- Copy macOS Contents.json
set macOSTemplatePath to "/Users/caishilin/Desktop/personal/Scripts/AppleIconExporter/macOS Contents.json"
set macOSJsonDest to macOSFolder & "/Contents.json"
do shell script "cp " & quoted form of macOSTemplatePath & " " & quoted form of macOSJsonDest

-- Show notification
display notification outputFolderName & " exported to Desktop" with title "Icon Exporter"

-- Open the base folder
do shell script "open " & quoted form of baseFolder
