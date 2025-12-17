# Cordova Vision Text Scanner Plugin

Cordova plugin for text detection using Apple VisionKit and Vision framework.

## Installation
```bash
cordova plugin add cordova-plugin-vision-text-scanner
cordova plugin add https://github.com/rajeshkumr/cordova-plugin-vision-text-scanner
```

## Usage

### Scan from Camera
```javascript
cordova.plugins.VisionTextScanner.scanFromCamera(
    function(result) {
        console.log("Detected text:", result.text);
        console.log("Image:", result.image); // base64
    },
    function(error) {
        console.error("Error:", error);
    },
    {} // options
);
```

### Scan from Gallery
```javascript
cordova.plugins.VisionTextScanner.scanFromGallery(
    function(result) {
        console.log("Detected text:", result.text);
    },
    function(error) {
        console.error("Error:", error);
    }
);
```

### Scan from Base64 Image
```javascript
var base64Image = "data:image/jpeg;base64,/9j/4AAQ...";

cordova.plugins.VisionTextScanner.scanFromBase64(
    base64Image,
    function(result) {
        console.log("Detected text:", result.text);
    },
    function(error) {
        console.error("Error:", error);
    }
);
```

## Requirements

- iOS 13.0+
- Cordova iOS 6.0+

## Permissions

The plugin automatically requests:
- Camera access
- Photo library access