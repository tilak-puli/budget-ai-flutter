# Budget AI Subscription API Specification

This document outlines the API endpoints for the Budget AI subscription system, including purchase verification, subscription status, and message quota management.

## Base URL

All API endpoints are relative to: `https://backend-2xqnus4dqq-uc.a.run.app`

## Authentication

All endpoints (except webhook notifications) require authentication using Firebase JWT tokens.

**Request Header:**

```
Authorization: Bearer <firebase_jwt_token>
```

## API Endpoints

### 1. Verify Purchase

Verifies a subscription purchase with Google Play and activates the subscription.

**Endpoint:** `POST /subscriptions/verify-purchase`

**Authentication:** Required

**Request Body:**

```json
{
  "packageName": "com.yourcompany.budgetai",
  "subscriptionId": "premium_monthly",
  "purchaseToken": "token_from_google_play",
  "platform": "android"
}
```

**Response (Success - 200):**

```json
{
  "success": true,
  "message": "Subscription verified and activated",
  "subscription": {
    "status": "active",
    "expiryDate": "2023-12-31T23:59:59Z",
    "autoRenewing": true
  }
}
```

**Response (Error - 400):**

```json
{
  "success": false,
  "message": "Invalid or inactive subscription",
  "error": "Error details"
}
```

### 2. Get Subscription Status

Returns the current user's subscription status.

**Endpoint:** `GET /subscriptions/status`

**Authentication:** Required

**Response (Success - 200):**

```json
{
  "success": true,
  "hasSubscription": true,
  "subscription": {
    "status": "active",
    "expiryDate": "2023-12-31T23:59:59Z",
    "autoRenewing": true,
    "platform": "android"
  }
}
```

**Response (No Subscription - 200):**

```json
{
  "success": true,
  "hasSubscription": false,
  "message": "No active subscription found"
}
```

### 3. Get Message Quota Status

Returns the user's current AI message quota status.

**Endpoint:** `GET /subscriptions/message-quota`

**Authentication:** Required

**Response (Success - 200):**

```json
{
  "success": true,
  "quota": {
    "hasQuotaLeft": true,
    "remainingQuota": 95,
    "isPremium": true,
    "dailyLimit": 100,
    "standardLimit": 5,
    "premiumLimit": 100
  }
}
```

### 4. Create AI Expense (Updated with Quota Information)

Creates an expense using AI, with quota tracking.

**Endpoint:** `POST /ai/expense`

**Authentication:** Required

**Request Body:**

```json
{
  "userMessage": "I spent $10 on coffee yesterday",
  "date": "2023-04-15T12:00:00Z" // Optional
}
```

**Response (Success - 200):**

```json
{
  "expense": {
    "_id": "6098a7b9b54c3e001c3d5678",
    "description": "Coffee",
    "amount": 10,
    "category": "Food & Drink",
    "date": "2023-04-14T12:00:00Z",
    "createdAt": "2023-04-15T12:00:00Z",
    "userId": "user123",
    "prompt": "I spent $10 on coffee yesterday"
  },
  "remainingQuota": 99,
  "dailyLimit": 100,
  "isPremium": true
}
```

**Response (Quota Exceeded - 403):**

```json
{
  "errorMessage": "Daily message limit (5) reached. Upgrade to premium for 100 AI messages per day.",
  "quotaExceeded": true,
  "remainingQuota": 0,
  "dailyLimit": 5,
  "isPremium": false
}
```

## Subscription Plans

### Free Tier

- 5 AI-generated expenses per day
- Basic expense tracking features

### Premium Tier (Monthly/Annual)

- 100 AI-generated expenses per day
- All basic features
- Premium-only features (TBD)

## Message Quota Details

The system tracks AI message usage on a daily basis (resets at midnight UTC):

- Free users: 5 messages per day
- Premium users: 100 messages per day

When a user reaches their daily limit, they will receive a quota exceeded error with a prompt to upgrade to premium.

## Error Codes

| Status Code | Description                                       |
| ----------- | ------------------------------------------------- |
| 200         | Success                                           |
| 400         | Bad Request - Invalid parameters                  |
| 401         | Unauthorized - Authentication required            |
| 403         | Forbidden - Quota exceeded or unauthorized access |
| 404         | Not Found - Resource not found                    |
| 500         | Server Error                                      |

## Implementation Examples

### Verifying a Purchase (Frontend)

```javascript
async function verifySubscription(purchaseToken) {
  try {
    const response = await fetch(
      "https://backend-2xqnus4dqq-uc.a.run.app/subscriptions/verify-purchase",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${firebaseToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          packageName: "com.yourcompany.budgetai",
          subscriptionId: "premium_monthly",
          purchaseToken: purchaseToken,
          platform: "android",
        }),
      }
    );

    const data = await response.json();

    if (data.success) {
      // Subscription verified successfully
      return {
        success: true,
        subscription: data.subscription,
      };
    } else {
      // Verification failed
      return {
        success: false,
        error: data.message,
      };
    }
  } catch (error) {
    console.error("Error verifying subscription:", error);
    return {
      success: false,
      error: "Network error",
    };
  }
}
```

### Checking Quota Status (Frontend)

```javascript
async function checkQuotaStatus() {
  try {
    const response = await fetch(
      "https://backend-2xqnus4dqq-uc.a.run.app/subscriptions/message-quota",
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${firebaseToken}`,
        },
      }
    );

    const data = await response.json();

    if (data.success) {
      // Display quota information to user
      const { remainingQuota, dailyLimit, isPremium } = data.quota;

      if (isPremium) {
        return `Premium account: ${remainingQuota}/${dailyLimit} AI messages remaining today`;
      } else {
        return `Free account: ${remainingQuota}/${dailyLimit} AI messages remaining today. Upgrade to premium for ${data.quota.premiumLimit} messages per day!`;
      }
    }
  } catch (error) {
    console.error("Error checking quota status:", error);
    return "Unable to check quota status";
  }
}
```

### Handling Quota Exceeded Errors (Frontend)

```javascript
async function createAIExpense(message) {
  try {
    const response = await fetch(
      "https://backend-2xqnus4dqq-uc.a.run.app/ai/expense",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${firebaseToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          userMessage: message,
        }),
      }
    );

    const data = await response.json();

    if (response.status === 403 && data.quotaExceeded) {
      // Show upgrade prompt to user
      showUpgradeDialog(`You've reached your daily limit of ${data.dailyLimit} AI messages. 
                         Upgrade to premium for ${data.isPremium ? "more" : "100"} messages per day!`);
      return null;
    }

    if (data.expense) {
      // Show remaining quota information
      showQuotaInfo(
        `${data.remainingQuota}/${data.dailyLimit} AI messages remaining today`
      );
      return data.expense;
    }
  } catch (error) {
    console.error("Error creating AI expense:", error);
    return null;
  }
}
```
