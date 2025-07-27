// This file is used to manually initialize Firebase in the web version if needed
// The configuration will be auto-injected by Flutter Firebase web plugins
document.addEventListener('DOMContentLoaded', function() {
  // Firebase will be automatically initialized by the Flutter Firebase plugins
  // This file exists as a fallback in case there are issues with auto-initialization
  
  // Check if Firebase is already initialized
  if (typeof firebase === 'undefined') {
    console.error('Firebase SDK not loaded. Make sure Firebase SDK scripts are properly included.');
  } else {
    console.log('Firebase SDK detected.');
  }
}); 