# Budget AI Subscription API - Quick Reference

## Overview

The Budget AI API now includes a subscription system with tiered message quotas:

- **Free users**: 5 AI messages per day
- **Premium users**: 100 AI messages per day

## Authentication

All endpoints require Firebase JWT tokens:

```
Authorization: Bearer <firebase_jwt_token>
```

## Key Endpoints

### 1. Verify Purchase

```
POST /subscriptions/verify-purchase
```

Activates a premium subscription after verifying the purchase with Google Play.

### 2. Check Subscription Status

```
GET /subscriptions/status
```

Returns whether the user has an active subscription.

### 3. Check Message Quota

```
GET /subscriptions/message-quota
```

Returns the user's remaining messages for the day.

### 4. Create AI Expense (Updated)

```
POST /ai/expense
```

Now includes quota tracking with modified response format.

## Response Examples

### Subscription Status Response

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

### Message Quota Response

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

### AI Expense Response (New Format)

```json
{
  "expense": {
    "_id": "6098a7b9b54c3e001c3d5678",
    "description": "Coffee",
    "amount": 10,
    "category": "Food & Drink",
    "date": "2023-04-14T12:00:00Z"
  },
  "remainingQuota": 99,
  "dailyLimit": 100,
  "isPremium": true
}
```

### Quota Exceeded Error

```json
{
  "errorMessage": "Daily message limit (5) reached. Upgrade to premium for 100 AI messages per day.",
  "quotaExceeded": true,
  "remainingQuota": 0,
  "dailyLimit": 5,
  "isPremium": false
}
```

## Integration Notes

1. The frontend should display remaining quota to users after each AI interaction
2. When quotas are exceeded, prompt users to upgrade to premium
3. Check quota status when initializing the app to show appropriate UI
4. After subscription purchase, verify with backend before enabling premium features
