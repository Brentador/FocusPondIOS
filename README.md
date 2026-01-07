# FocusPond iOS

A gamified study timer app for iOS that helps users stay focused by growing virtual fish. Study to make your fish grow, earn coins, and build your own pond ecosystem!

## Features

### Core Functionality
- **Study Timer**: Customizable focus timer (1-120 minutes) with pause/resume
- **Fish Growth System**: Watch your fish grow through 3 stages (Egg → Fry → Adult)
- **Virtual Pond**: Animated pond displaying your fully-grown fish
- **Shop System**: Purchase new fish species with earned coins
- **Weather Integration**: Real-time weather effects based on your location
- **Multi-user Support**: Individual accounts with login/registration

### Technical Features
- **Offline Support**: Full functionality with local data caching
- **Data Persistence**: All progress saved and synced with backend
- **Real-time Updates**: Fish animations and weather changes
- **Progress Tracking**: View study time and growth progress

## Architecture

### Tech Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS**: 15.0
- **Dependencies**: Kingfisher (image loading)

### Project Structure
```
FocusPondIOS/
├── FocusPond/
│   ├── Models/              # Data models
│   │   ├── Fish.swift
│   │   ├── Currency.swift
│   │   └── TimerStateModel.swift
│   ├── ViewModels/          # Business logic
│   │   ├── PondViewModel.swift
│   │   └── TimerViewModel.swift
│   ├── Views/               # SwiftUI Views
│   │   ├── User/            # Login/Register
│   │   ├── Timer/           # Study timer
│   │   ├── Shop/            # Fish shop
│   │   └── Pond/            # Animated pond
│   ├── Services/            # Managers & Services
│   │   ├── FishManager.swift
│   │   ├── WeatherService.swift
│   │   ├── AuthService.swift
│   │   └── CacheService.swift
│   └── Data/
│       ├── APIService.swift


```

## Setup Instructions

### Prerequisites
- **Xcode**: 15.0 or later
- **iOS Device/Simulator**: iOS 15.0+
- **Backend**: FastAPI with SQLite (see [FocusPondDB](https://github.com/Brentador/FocusPondDB))

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Brentador/FocusPondIOS.git
   cd FocusPondIOS
   ```

2. **Install Kingfisher**:

   **Swift Package Manager**
   - Open `FocusPondIOS.xcodeproj` in Xcode
   - File → Add Packages
   - Search: `https://github.com/onevcat/Kingfisher.git`
   - Click "Add Package"



3. **Configure Info.plist**:
   
   Verify `Info.plist` contains location permission:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We use your location to display weather effects in your pond</string>

4. **Start the backend**:
   ```bash
   cd FocusPondDB
   # Follow FocusPondDB/README.md for setup (https://github.com/Brentador/FocusPondDB)
   ```

5. **Run the app**:
   - Select a simulator or device in Xcode
   - Build the project
   - **Important**: Backend must be running on `http://localhost:8000`
