# Finly - Budget AI Flutter App Setup Guide

This guide will help you set up the Finly budget tracking app with AI capabilities.

## Prerequisites

- Flutter SDK (3.7.2 or higher)
- Firebase account
- Android Studio / Xcode (for mobile development)
- A backend API server (or Firebase Functions)

## 🔧 Initial Setup

### 1. Clone and Install Dependencies

```bash
git clone <your-repo-url>
cd budget-ai-flutter
flutter pub get
```

### 2. Configuration Setup

#### Create Local Configuration

1. Copy the configuration template:

   ```bash
   cp lib/config/local_config.dart.template lib/config/local_config.dart
   ```

2. Update `lib/config/local_config.dart` with your actual values:
   - Replace `YOUR_BACKEND_HOST` with your backend server URL
   - Replace `YOUR_PROJECT_ID` with your Firebase project ID
   - Replace all Firebase API keys with your actual keys

#### Firebase Configuration

#### Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication (Google Sign-In)
4. Enable Firestore Database
5. Enable Storage

#### Configure Firebase for Each Platform

**Android:**

1. Add your Android app to Firebase project
2. Download `google-services.json`
3. Copy it to `android/app/google-services.json`

**iOS:**

1. Add your iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Copy it to `ios/Runner/GoogleService-Info.plist`

**macOS:**

1. Add your macOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Copy it to `macos/Runner/GoogleService-Info.plist`

### 3. Backend API Configuration

The backend API configuration is now handled through the `lib/config/local_config.dart` file.
Make sure to update the `backendHost` value in your local configuration file.

### 4. Android Signing (for Release Builds)

1. Generate a signing key:

   ```bash
   keytool -genkey -v -keystore android/app/release-key -keyalg RSA -keysize 2048 -validity 10000 -alias key0
   ```

2. Create `android/key.properties`:
   ```
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=key0
   storeFile=./release-key
   ```

## 🚀 Running the App

### Development Mode

```bash
flutter run
```

### Release Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release
```

## 📱 Features

- **AI-Powered Expense Tracking**: Add expenses using natural language
- **Budget Management**: Set and track budgets by category
- **Multi-Platform**: Works on Android, iOS, macOS, and Web
- **Firebase Authentication**: Secure Google Sign-In
- **Real-time Sync**: Data synced across all devices
- **Location-Based Expenses**: Automatic location tagging
- **Subscription Management**: In-app purchase support

## 🔒 Security Notes

- Never commit sensitive files like `google-services.json`, `GoogleService-Info.plist`, or `key.properties`
- Use environment variables for API keys in production
- Keep your Firebase project secure with proper security rules
- Regularly rotate API keys and certificates

## 🛠 Development

### Project Structure

```
lib/
├── components/          # Reusable UI components
├── constants/          # App constants and configuration
├── models/            # Data models
├── pages/             # Main app pages
├── screens/           # Individual screens
├── services/          # API and business logic services
├── state/             # State management (Provider)
├── theme/             # App theming and styling
└── utils/             # Utility functions
```

### Adding New Features

1. Create models in `lib/models/`
2. Add API services in `lib/services/`
3. Create UI components in `lib/components/`
4. Add screens in `lib/screens/`
5. Update state management in `lib/state/`

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For support, please open an issue in the GitHub repository or contact the development team.
