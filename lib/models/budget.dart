var budgetList = [
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
  "Insurance"
];

class Budget {
  Map<String, num> map = Map.of({
    "food": 3000,
    "transport": 1000,
    "rent": 7000,
    "entertainment": 2000,
    "utilities": 2000,
    "groceries": 2000,
    "shopping": 4000,
    "healthcare": 500,
    "personal care": 1000,
    "misc": 1000,
    "savings": 5000
  });

  get total => map.values.reduce((value, element) => value + element);

  updateAmount(String category, num amount) {
    map[category.toLowerCase()] = amount;
  }

  num getAmount(String category) => map[category.toLowerCase()] ?? 100;
}
