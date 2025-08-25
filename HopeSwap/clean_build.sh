#!/bin/bash

echo "Cleaning Xcode build..."

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean project
xcodebuild clean -project HopeSwap.xcodeproj -scheme HopeSwap

echo "Build cleaned. Please rebuild the project in Xcode."