# Initialization API Specification

## Endpoint Overview

- **URL**: `/app/init`
- **Method**: `GET`
- **Authentication**: Required (Firebase token)
- **Description**: Initializes the app by retrieving user expenses, quota information, budget details, and configuration settings.

## Request Parameters

- **fromDate** (optional): Start date for expense retrieval (format: ISO string)
- **toDate** (optional): End date for expense retrieval (format: ISO string)
  - If not provided, defaults to current month

## Response Structure

```json
{
  "expenses": [
    {
      "_id": "string",
      "userId": "string",
      "category": "string",
      "description": "string",
      "amount": "number",
      "date": "string" // ISO date
    }
  ],

  "quota": {
    "hasQuotaLeft": "boolean",
    "remainingQuota": "number",
    "isPremium": "boolean",
    "dailyLimit": "number",
    "standardLimit": "number",
    "premiumLimit": "number"
  },

  "budget": {
    "budget": {
      "totalBudget": "number",
      "categoryBudgets": {
        "Food": "number",
        "Transport": "number"
        // other categories...
      },
      "_id": "string" // only if budgetExists is true
    },
    "categories": ["string"], // list of available categories
    "budgetExists": "boolean"
  },

  "budgetSummary": {
    "totalBudget": "number",
    "totalSpending": "number",
    "remainingBudget": "number",
    "categories": [
      {
        "category": "string",
        "budget": "number",
        "actual": "number",
        "remaining": "number"
      }
    ],
    "month": "number", // 1-12
    "year": "number", // e.g., 2023
    "budgetExists": "boolean"
  },

  "featureFlags": {
    "enableBudgetFeature": "boolean",
    "enableAIExpenses": "boolean",
    "enableCategoryCustomization": "boolean",
    "enableDataExport": "boolean",
    "enableWhatsappIntegration": "boolean"
    // May include additional feature flags from the config table
  },

  "config": {
    // All configuration from the config table
    // Each document in the table has key-value pairs
    "key1": "value1",
    "key2": "value2"
    // ... more key-value pairs
  },

  "dateRange": {
    "fromDate": "string", // ISO date
    "toDate": "string" // ISO date
  }
}
```

## Feature Flags

The `featureFlags` object contains boolean flags controlling feature availability:

- **enableBudgetFeature**: Controls if budget functionality is enabled
- **enableAIExpenses**: Controls AI-based expense analysis
- **enableCategoryCustomization**: Controls custom expense categories
- **enableDataExport**: Controls data export functionality
- **enableWhatsappIntegration**: Controls WhatsApp integration

## Config Table Structure

The config table stores application settings with the following structure:

- Each document contains `key` and `value` fields
- The API returns all config values in the `config` object
- Feature flags are specifically extracted into the `featureFlags` object

## Error Responses

- **400 Bad Request**: Invalid user
  ```json
  {
    "errorMessage": "Invalid User"
  }
  ```
- **500 Internal Server Error**: Server-side error
  ```json
  {
    "success": false,
    "errorMessage": "Failed to initialize app",
    "error": "Error details"
  }
  ```
