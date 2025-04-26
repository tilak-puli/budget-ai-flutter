# Budget API - Quick Reference

## Authentication

All endpoints require Firebase JWT token in Authorization header.

## Available Categories

```
Food, Transport, Rent, Entertainment, Utilities, Groceries, Shopping,
Healthcare, Personal Care, Misc, Savings, Insurance, Lent
```

## API Endpoints

| Endpoint              | Method | Description                   | Request Body                                                | Query Params               |
| --------------------- | ------ | ----------------------------- | ----------------------------------------------------------- | -------------------------- |
| `/budgets`            | GET    | Get user budget configuration | -                                                           | -                          |
| `/budgets/total`      | POST   | Update total budget           | `{ "totalBudget": 5000 }`                                   | -                          |
| `/budgets/category`   | POST   | Update category budget        | `{ "category": "Food", "amount": 1000 }`                    | -                          |
| `/budgets/categories` | POST   | Update multiple categories    | `{ "categoryBudgets": { "Food": 1000, "Transport": 500 } }` | -                          |
| `/budgets/summary`    | GET    | Get budget vs spending        | -                                                           | `month`, `year` (optional) |
| `/budgets`            | DELETE | Delete user budget            | -                                                           | -                          |

## Response Structure Examples

### User Budget

```json
{
  "success": true,
  "budget": {
    "totalBudget": 5000,
    "categoryBudgets": { "Food": 1000, ... },
    "_id": "budget-id"
  },
  "categories": ["Food", "Transport", ...]
}
```

### Budget Summary

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
      ...
    ],
    "month": 4,
    "year": 2023
  }
}
```

## Key Implementation Notes

1. Budget is a global configuration that applies to all months
2. Budget summary provides month-specific spending data
3. All amounts should be handled as numbers/floats
4. Invalid categories will return validation errors
5. Summary data can be requested for any month/year
