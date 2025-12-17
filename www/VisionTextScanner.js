var exec = require('cordova/exec');

var VisionTextScanner = {
    /**
     * Scan text from camera
     * @param {Function} successCallback - Success callback with recognized text
     * @param {Function} errorCallback - Error callback
     * @param {Object} options - Configuration options
     */
    scanFromCamera: function(successCallback, errorCallback, options) {
        options = options || {};
        exec(successCallback, errorCallback, 'VisionTextScanner', 'scanFromCamera', [options]);
    },
    
    /**
     * Scan text from photo library
     * @param {Function} successCallback - Success callback with recognized text
     * @param {Function} errorCallback - Error callback
     * @param {Object} options - Configuration options
     */
    scanFromGallery: function(successCallback, errorCallback, options) {
        options = options || {};
        exec(successCallback, errorCallback, 'VisionTextScanner', 'scanFromGallery', [options]);
    },
    
    /**
     * Scan text from base64 image
     * @param {String} base64Image - Base64 encoded image
     * @param {Function} successCallback - Success callback with recognized text
     * @param {Function} errorCallback - Error callback
     */
    scanFromBase64: function(base64Image, successCallback, errorCallback) {
        exec(successCallback, errorCallback, 'VisionTextScanner', 'scanFromBase64', [base64Image]);
    }
};

module.exports = VisionTextScanner;