# 📱 iOS Simulator Setup Guide

## Prerequisites
- macOS with Xcode installed
- Flutter SDK configured
- iOS Simulator available

## Quick Setup Commands

```bash
# Navigate to the mobile directory
cd /Users/macbookair/Downloads/silos/mobile

# Install dependencies
flutter pub get

# Check available iOS simulators
flutter devices

# Run on iOS Simulator
flutter run -d ios

# Or run on specific iOS device
flutter run -d "iPhone 15 Pro"
```

## iOS Simulator Commands

```bash
# Open iOS Simulator
open -a Simulator

# List available simulators
xcrun simctl list devices

# Boot a specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Install app on simulator
flutter install -d ios
```

## Build for iOS

```bash
# Debug build
flutter build ios --debug

# Release build  
flutter build ios --release

# Build for specific architecture
flutter build ios --release --target-platform ios-arm64
```

## Features Implemented

✅ **Exact React Interface Match**
- Live Readings with silo grid layout
- Weather Station widget
- Sensor readings panel
- Grain level panel
- Alert monitoring page
- Reports & Analytics with charts
- Settings page with configuration options

✅ **Responsive Design**
- Adaptive layouts for different screen sizes
- Touch-friendly interface
- Optimized for mobile interaction

✅ **Beautiful Animations**
- Smooth page transitions
- Interactive elements
- Loading states
- Micro-interactions

✅ **Clean Architecture**
- BLoC pattern for state management
- Dependency injection
- Separation of concerns
- Scalable code structure

## Test Credentials
- `bashar/bashar` (Operator)
- `ahmed/ahmed` (Admin)
- `hussien/hussien` (Technician)

## API Integration Ready
The app is structured to connect to the existing Node.js backend:
- Base URL: `http://idealchiprnd.pythonanywhere.com`
- Same endpoints as React app
- JWT authentication system
- Real-time data capabilities
