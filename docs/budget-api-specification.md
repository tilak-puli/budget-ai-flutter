# Budget Management API Specification

## Overview

The Budget Management API allows users to set budgets for both total monthly spending and category-specific spending. This document provides specifications for integrating with the Budget API endpoints.

Key features:

- Global user budget configuration that applies to all months
- Category-specific budget allocations
- Monthly spending tracking against budget
- Support for all expense categories used in the app

## Authentication

All endpoints require authentication using Firebase JWT tokens:

```
Authorization: Bearer <firebase_jwt_token>
```

## API Endpoints

### 1. Get User Budget

Retrieve the user's budget configuration.

**Endpoint:** `GET /budgets`

**Response:**

```json
{
  "success": true,
  "budget": {
    "totalBudget": 5000,
    "categoryBudgets": {
      "Food": 1000,
      "Transport": 500,
      "Shopping": 800
      // other categories as configured
    },
    "_id": "budget-document-id"
  },
  "categories": [
    "Food",
    "Transport",
    "Rent",
    "Entertainment",
    "Utilities",
    "Groceries",
    "Shopping",
    "Healthcare",
    "Personal Care",
    "Misc",
    "Savings",
    "Insurance",
    "Lent"
  ]
}
```

### 2. Update Total Budget

Set the total monthly budget for the user.

**Endpoint:** `POST /budgets/total`

**Request Body:**

```json
{
  "totalBudget": 5000
}
```

**Response:**

```json
{
  "success": true,
  "budget": {
    "totalBudget": 5000,
    "categoryBudgets": {
      // existing category budgets
    },
    "_id": "budget-document-id"
  }
}
```

### 3. Update Category Budget

Set the budget for a specific expense category.

**Endpoint:** `POST /budgets/category`

**Request Body:**

```json
{
  "category": "Food",
  "amount": 1000
}
```

**Response:**

```json
{
  "success": true,
  "budget": {
    "totalBudget": 5000,
    "categoryBudgets": {
      "Food": 1000
      // other categories
    },
    "_id": "budget-document-id"
  }
}
```

### 4. Update Multiple Category Budgets

Set budgets for multiple expense categories at once.

**Endpoint:** `POST /budgets/categories`

**Request Body:**

```json
{
  "categoryBudgets": {
    "Food": 1000,
    "Transport": 500,
    "Shopping": 800
  }
}
```

**Response:**

```json
{
  "success": true,
  "budget": {
    "totalBudget": 5000,
    "categoryBudgets": {
      "Food": 1000,
      "Transport": 500,
      "Shopping": 800
      // other existing categories remain unchanged
    },
    "_id": "budget-document-id"
  }
}
```

### 5. Get Budget Summary with Spending Comparison

Get budget status with actual spending for the current month (or specified month).

**Endpoint:** `GET /budgets/summary`

**Query Parameters (optional):**

- `month`: Month number (1-12) - defaults to current month
- `year`: Year (e.g., 2023) - defaults to current year

**Response:**

```json
{
  "success": true,
  "summary": {
    "totalBudget": 5000,
    "totalSpending": 3200,
    "remainingBudget": 1800,
    "categories": [
      {
        "category": "Food",
        "budget": 1000,
        "actual": 850,
        "remaining": 150
      },
      {
        "category": "Transport",
        "budget": 500,
        "actual": 450,
        "remaining": 50
      }
      // All other categories with their budget, actual and remaining values
    ],
    "month": 4,
    "year": 2023,
    "_id": "budget-document-id"
  }
}
```

### 6. Delete Budget

Delete the budget configuration for a user.

**Endpoint:** `DELETE /budgets`

**Response:**

```json
{
  "success": true,
  "deleted": true
}
```

## Error Responses

All endpoints return appropriate error responses with HTTP status codes:

**400 Bad Request:**

```json
{
  "success": false,
  "errorMessage": "Error message explaining the issue"
}
```

**Invalid Category:**

```json
{
  "success": false,
  "errorMessage": "Invalid category",
  "validCategories": ["Food", "Transport", "Rent", ...]
}
```

**500 Server Error:**

```json
{
  "success": false,
  "errorMessage": "Failed to get budget information",
  "error": "Detailed error message"
}
```

## Integration Guidelines

1. **Initialization**: Fetch the user's budget configuration when they view the budget section using the `GET /budgets` endpoint.

2. **Budget Setup**: If the user doesn't have a budget yet (empty `categoryBudgets` object and `totalBudget` of 0), prompt them to set up their budget.

3. **Budget Updates**: Use the appropriate endpoints to update budgets based on user actions:

   - For setting a single overall budget: use `/budgets/total`
   - For setting category-specific budgets: use `/budgets/category` or `/budgets/categories` for batch updates

4. **Monthly Tracking**: Display the budget vs. actual spending using the `/budgets/summary` endpoint. This can be refreshed whenever new expenses are added.

5. **Historical View**: Use the query parameters for the `/budgets/summary` endpoint to let users view previous months' performance against their budget.

## Example Implementation

```javascript
// Get user budget
async function getUserBudget() {
  try {
    const response = await fetch("https://your-api-url.com/budgets", {
      method: "GET",
      headers: {
        Authorization: `Bearer ${firebaseToken}`,
        "Content-Type": "application/json",
      },
    });
    return await response.json();
  } catch (error) {
    console.error("Error fetching budget:", error);
    return { success: false, error: error.message };
  }
}

// Set total budget
async function setTotalBudget(amount) {
  try {
    const response = await fetch("https://your-api-url.com/budgets/total", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${firebaseToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ totalBudget: amount }),
    });
    return await response.json();
  } catch (error) {
    console.error("Error setting total budget:", error);
    return { success: false, error: error.message };
  }
}

// Get monthly budget summary
async function getBudgetSummary(month, year) {
  const queryParams = new URLSearchParams();
  if (month) queryParams.append("month", month);
  if (year) queryParams.append("year", year);

  try {
    const response = await fetch(
      `https://your-api-url.com/budgets/summary?${queryParams}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${firebaseToken}`,
          "Content-Type": "application/json",
        },
      }
    );
    return await response.json();
  } catch (error) {
    console.error("Error fetching budget summary:", error);
    return { success: false, error: error.message };
  }
}
```
