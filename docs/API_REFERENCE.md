# SpendMate API Reference & Specification

Base URL: `http://localhost:5000/api/v1`

All requests should supply standard JSON payloads and include the Bearer token header where authenticated:
`Authorization: Bearer <jwt_token>`

---

## Response Envelope Formats

### Standard Success Response
```json
{
  "success": true,
  "message": "Success",
  "data": {},
  "meta": {}
}
```

### Standard Error Response
```json
{
  "success": false,
  "message": "Error description",
  "errors": []
}
```

---

## 1. Authentication & User Profiles

### `POST /auth/send-otp`
Sends 6-digit verification code. In development, OTP is `123456`.
```json
{
  "phoneNumber": "+919876543210"
}
```

### `POST /auth/verify-otp`
Verifies OTP and returns access token + refresh token.
```json
{
  "phoneNumber": "+919876543210",
  "otp": "123456"
}
```

### `POST /auth/profile-setup` (Auth Required)
Configures user full name, currency, monthly target.
```json
{
  "name": "Kunal Verma",
  "email": "kunal@example.com",
  "currency": "INR",
  "monthlyBudgetPaise": 5000000,
  "themePreference": "light"
}
```

---

## 2. Personal Finance Endpoints

### `GET /wallets`
Retrieves user financial accounts (bank, cash, UPI, credit cards) and total liquidity in paise.

### `GET /transactions`
Queries user transactions with filters:
`?type=expense&limit=20&page=1&search=coffee`

### `POST /transactions`
Creates transaction and atomically updates wallet balance.
```json
{
  "walletId": "65b...",
  "categoryId": "65c...",
  "amountPaise": 48000,
  "type": "expense",
  "description": "Blue Tokai Coffee Roasters",
  "notes": "Specialty flat white"
}
```

### `GET /budgets`
Retrieves monthly category budgets and spending progress.

### `GET /savings`
Retrieves active savings goals and deposit balances.

### `GET /analytics/dashboard`
Aggregated cashflow summary, category percentages, and velocity.

---

## 3. Trips & Multi-Payer Group Expenses

### `GET /trips`
Retrieves all user trips.

### `POST /trips`
Creates a new group trip with member names.
```json
{
  "title": "Manali Snow Expedition",
  "destination": "Manali, Himachal Pradesh",
  "startDate": "2026-11-18",
  "endDate": "2026-11-24",
  "totalBudgetPaise": 8000000,
  "memberNames": ["Aarav Sharma", "Rohan Mehra", "Pooja Nair"]
}
```

### `POST /trip-expenses`
Records a group expense with multi-payer contributors and deterministic splits.
```json
{
  "tripId": "65d...",
  "description": "Sightseeing & Shuttle Tickets",
  "amountPaise": 56000,
  "category": "Travel & Trips",
  "paidBy": [
    { "memberId": "member_A", "name": "Aarav Sharma", "amountPaise": 40000 },
    { "memberId": "member_C", "name": "Rohan Mehra", "amountPaise": 16000 }
  ],
  "splitType": "equal",
  "participantIds": ["member_A", "member_B", "member_C", "member_D"]
}
```

### `GET /settlements/trip/:tripId`
Calculates net balances and outputs minimal payments via the Debt Minimizer algorithm:
```json
{
  "success": true,
  "data": {
    "memberBalances": [
      { "memberId": "A", "name": "Aarav", "netBalancePaise": 96000 },
      { "memberId": "B", "name": "Kunal", "netBalancePaise": 16000 },
      { "memberId": "C", "name": "Rohan", "netBalancePaise": -48000 },
      { "memberId": "D", "name": "Pooja", "netBalancePaise": -64000 }
    ],
    "suggestedPayments": [
      { "fromName": "Rohan", "toName": "Aarav", "amountPaise": 48000 },
      { "fromName": "Pooja", "toName": "Aarav", "amountPaise": 48000 },
      { "fromName": "Pooja", "toName": "Kunal", "amountPaise": 16000 }
    ]
  }
}
```

---

## 4. Smart Financial Features

### `POST /receipts/scan`
Extracts line items, merchant name, and total amount from receipt photo.

### `POST /ai-assistant/chat`
Answers financial questions and analyzes trip budgets.

### `GET /recurring-expenses`
Lists repeating subscriptions and billing calendar dates.

### `GET /notifications`
User notifications inbox.

### `POST /sync/pull`
Delta offline sync endpoint.
