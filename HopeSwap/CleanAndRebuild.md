# Clean Build Instructions

To fix the black screen issue:

1. **Close Xcode completely**

2. **Delete Derived Data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. **Delete the app from simulator**:
   - Open Simulator
   - Long press the HopeSwap app
   - Click the X to delete it

4. **Clean project files**:
   ```bash
   cd /Users/jimmylam/Documents/HopeSwap/HopeSwap
   find . -name "*.xcuserstate" -delete
   find . -name "*.xcworkspace" -exec rm -rf {} \;
   ```

5. **Reopen Xcode** and open the project

6. **Clean Build Folder**:
   - Menu: Product → Clean Build Folder (or Cmd+Shift+K)

7. **Build and Run**:
   - Cmd+B to build
   - Cmd+R to run

## What was fixed:
- Removed duplicate Color init(hex:) declaration
- Fixed UIColor initialization in HopeSwapApp
- Simplified onAppear and onChange handlers
- Removed problematic MapView
- Temporarily disabled sample data loading

## If still black screen:
1. Check the Console output in Xcode for any runtime errors
2. Try running on a different simulator (iPhone 15 Pro recommended)
3. Reset simulator: Device → Erase All Content and Settings