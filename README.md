# MCATPrep iOS App

An adaptive MCAT preparation app that helps students achieve a target score of 515+ through personalized learning using Convolution-Augmented Knowledge Tracing (CAKT).

## Features

- **Adaptive Practice**: Questions are dynamically sequenced based on your knowledge state
- **Deck Practice**: Practice specific topics with curated question decks
- **Daily Drills**: Daily personalized practice sessions targeting weak areas
- **Full-length Exams**: Simulated MCAT exams with adaptive question selection
- **Offline Mode**: Study anywhere with offline support via SAKTLite algorithm
- **Progress Analytics**: Visual mastery heatmaps and performance tracking

## Architecture

### Core Components

- **SwiftUI-based UI**: Modern declarative UI framework
- **MVVM Architecture**: Clean separation of concerns with ViewModels
- **Combine Framework**: Reactive programming for data flow
- **Core Data**: Local storage for offline functionality
- **SAKTLite**: On-device algorithm for offline adaptive learning
- **CAKT Client**: Communication with server-side CAKT algorithm

### Directory Structure

```
MCATPrep/
├─ App/                    # Main application code
│  ├─ App/                 # App entry point
│  ├─ Modules/             # Feature modules
│  │  ├─ Authentication/
│  │  ├─ Decks/
│  │  ├─ Quiz/
│  │  ├─ Dashboard/
│  │  ├─ Profile/
│  │  └─ Purchase/
│  ├─ Coordinators/        # Navigation coordinators
│  ├─ Services/            # Core services
│  ├─ Extensions/          # Swift extensions
│  └─ Resources/           # Assets and resources
│
├─ Database/               # Database-related files
│  ├─ CoreDataModel/       # Core Data model
│  ├─ supabase/            # Supabase schema
│  └─ seed/                # Seed data
│
├─ Packages/               # Local Swift Packages
│  ├─ Algorithms/          # ML algorithms
│  │  ├─ SAKTLiteKit/      # Offline algorithm
│  │  └─ CAKTClient/       # Server algorithm client
│  ├─ MBFoundation/        # Core utilities
│  ├─ MBUI/                # UI components
│  └─ MBMocks/             # Test mocks
│
├─ Scripts/                # Build and developer scripts
└─ Tests/                  # Unit and UI tests
```

## Knowledge Tracing Algorithms

### CAKT (Server-side)

The Convolution-Augmented Knowledge Tracing algorithm runs on the server and uses a neural network to model student knowledge:

- Input window of 512 interactions
- Local learning-curve branch with 3D convolution
- Global branch with Bi-LSTM
- GPU-accelerated inference (<3ms)
- Estimates knowledge state as a 128-dimensional latent vector

### SAKTLite (On-device)

A simplified version of Self-Attention Knowledge Tracing that runs on-device for offline mode:

- Tracks up to 512 recent interactions
- Uses lightweight dot-product attention
- Updates a 64-dimensional user skill vector
- Provides adaptive question sequencing for offline use

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Swift 5.9+
- [CocoaPods](https://cocoapods.org) or [Swift Package Manager](https://swift.org/package-manager/)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/mcatprep-ios.git
   ```

2. Open the workspace:
   ```
   open MCATPrep.xcworkspace
   ```

3. Build and run the app in Xcode.

## Configuration

Environment-specific configuration is managed in the `ConfigurationManager.swift` file.

## Development

### Testing Offline Mode

To test offline functionality:
1. Enable airplane mode on your device
2. Complete a few practice questions
3. Observe that results are stored locally
4. Re-enable connectivity and verify sync occurs

## License

This project is proprietary software. All rights reserved.

---

© 2025 MCATPrep
