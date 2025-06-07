# Finly

## Project Overview

Finly (formerly Budget AI/Coin Master AI) is a Flutter-based mobile application designed to simplify expense tracking and budgeting with the help of artificial intelligence. The app allows users to add expenses by describing them in natural language, and the AI automatically categorizes and processes these descriptions into structured expense entries.

## Key Features

- **AI-Powered Expense Tracking**: Describe your expenses in plain text, and the AI will extract relevant details and categorize them
- **Expense Management**: View, edit, and delete expense entries
- **Budget Monitoring**: Track spending against category-specific budgets
- **Authentication**: Secure sign-in using Firebase Authentication with Google Sign-In
- **Freemium Model**: Free tier with limited daily messages, premium subscription for unlimited usage

## Technical Architecture

### Frontend

- **Framework**: Flutter
- **State Management**: Provider pattern with ChangeNotifier
- **UI Components**: Material Design with custom components

### Backend

- **API**: RESTful API service for AI processing (backend-2xqnus4dqq-uc.a.run.app)
- **Authentication**: Firebase Authentication
- **Local Storage**: SharedPreferences for caching expense data

### Core Components

#### Authentication

- Firebase Authentication with Google Sign-In
- AuthGate component to handle authentication state and routing

#### Data Models

- **Expense**: Stores expense information including amount, category, description, date, and the original prompt
- **Budget**: Tracks category-specific budget amounts
- **Expenses**: A collection class for managing multiple expense entries

#### State Management

- **ExpenseStore**: Manages expense data, including CRUD operations and localStorage synchronization
- **ChatStore**: Handles the chat interface state including message history

#### Services

- **ApiService**: Handles communication with the backend API
- **SubscriptionService**: Manages the freemium model with daily message limits for free users

#### UI Components

- **ChatBox**: Displays conversation with the AI
- **ExpenseCard**: Visualizes individual expense entries
- **AIMessageInput**: Input field for sending messages to the AI
- **BudgetStatus**: Displays budget progress and category-specific spending

## Freemium Model

The app implements a subscription-based freemium model:

- **Free Tier**: Limited to 5 AI messages per day
- **Premium**: Unlimited messages and interactions
- Integration with in_app_purchase for handling subscriptions

## Workflow

1. **User Authentication**: Users sign in using their Google account
2. **Expense Addition**:
   - User enters a natural language description (e.g., "Spent $25 on lunch at McDonald's yesterday")
   - The message is sent to the backend AI service
   - AI extracts the amount, category, description, and date
   - A structured expense entry is created and stored
3. **Expense Viewing**: Users can view their expenses in a list or chat interface
4. **Budget Tracking**: The app shows budget progress based on spending in each category

## Technical Implementation Details

### Message Limiting System

- SharedPreferences tracks daily message count and last reset date
- Counter resets at midnight
- Premium users bypass the message limit check

### Expense Processing

- Messages are sent to backend API
- API returns structured expense data
- Expenses are stored locally and displayed to the user

### Data Synchronization

- Local expense data is cached in SharedPreferences
- New expenses from the API are merged with local data
- Optimized merging algorithm for maintaining sorted order

## Project Structure

```
lib/
├── api.dart                  - API service implementation
├── app.dart                  - Main app configuration
├── auth_gate.dart            - Authentication handling
├── main.dart                 - Application entry point
├── components/               - Reusable UI components
│   ├── AI_message_input.dart - Input field for AI messages
│   ├── body_tabs.dart        - Tab navigation
│   ├── budget_status.dart    - Budget visualization
│   ├── chatbox.dart          - Chat interface
│   ├── expense_card.dart     - Individual expense display
│   └── ...
├── models/                   - Data structures
│   ├── expense.dart          - Expense model
│   ├── expense_list.dart     - Collection of expenses
│   └── budget.dart           - Budget model
├── pages/                    - Application screens
│   ├── homepage.dart         - Main app screen
│   └── login.dart            - Authentication screen
├── screens/                  - Additional screens
├── services/                 - Business logic services
│   └── subscription_service.dart - Subscription management
├── state/                    - State management
│   ├── chat_store.dart       - Chat interface state
│   └── expense_store.dart    - Expense data state
└── utils/                    - Utility functions
```

## Dependencies

- **flutter_easyloading**: Loading indicators
- **intl**: Internationalization and date formatting
- **month_year_picker**: Date selection
- **syncfusion_flutter_charts**: Data visualization
- **provider**: State management
- **firebase_core**, **firebase_auth**: Authentication
- **firebase_ui_auth**, **firebase_ui_oauth_google**: UI for authentication
- **shared_preferences**: Local storage
- **in_app_purchase**: Subscription handling

## Development Status

The project appears to be under active development, with recent implementations focusing on the subscription service and message limiting functionality. The subscription service is currently being integrated with the rest of the application.

## Getting Started

### Prerequisites

- Flutter SDK
- Firebase project with Authentication enabled
- Google Cloud project for backend API

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   - Create a Firebase project
   - Enable Google Authentication
   - Add your app to the Firebase project
   - Download and add the `google-services.json` and `GoogleService-Info.plist` files
4. Run the app with `flutter run`

### Configuration

- Update the API endpoint in `api.dart` if needed
- Configure your subscription product IDs in `subscription_service.dart`
