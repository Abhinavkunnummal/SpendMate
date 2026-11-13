# SpendMate

> **Track Money. Plan Trips. Split Smartly.**

SpendMate is a full-stack personal finance and group expense management mobile application with an Apple-inspired design language. Built from Google Stitch UI designs (Project ID: `7940772611928863336`), it combines personal financial tracking, multi-payer trip expense splitting, and a greedy Debt Minimizer algorithm.

---

## 📱 24 Canonical Screens

SpendMate faithfully implements all 24 Stitch screens across 16 feature modules:

| # | Screen Name | Feature Path | Description |
|---|---|---|---|
| 1 | **Welcome** | `mobile/lib/features/auth/presentation/welcome_screen.dart` | Apple Wallet style hero cards, value pillars, entry CTA |
| 2 | **Phone Login & OTP** | `mobile/lib/features/auth/presentation/phone_login_screen.dart` | +91 country input, 6-digit OTP fields, resend countdown |
| 3 | **Profile Setup** | `mobile/lib/features/auth/presentation/profile_setup_screen.dart` | Avatar selector, currency choice, monthly target |
| 4 | **Home Dashboard** | `mobile/lib/features/dashboard/presentation/dashboard_screen.dart` | Net worth card, quick actions, budget progress, trips preview |
| 5 | **All Transactions** | `mobile/lib/features/transactions/presentation/transactions_screen.dart` | Search, type filter chips, date-grouped transaction lists |
| 6 | **Add Expense / Income** | `mobile/lib/features/transactions/presentation/add_transaction_screen.dart` | Segmented toggle, hero amount, categories, wallets |
| 7 | **Transaction Details** | `mobile/lib/features/transactions/presentation/transaction_details_screen.dart` | Large status badge, breakdown card, receipt viewer |
| 8 | **Wallets** | `mobile/lib/features/wallets/presentation/wallets_screen.dart` | Total liquidity card, accounts (Bank, UPI, Cards, Cash) |
| 9 | **Budgets** | `mobile/lib/features/budgets/presentation/budgets_screen.dart` | Monthly spending limit, category progress bars, alerts |
| 10 | **Savings Goals** | `mobile/lib/features/savings/presentation/savings_screen.dart` | Portfolio summary, active goals, deposits & progress |
| 11 | **Analytics & Reports** | `mobile/lib/features/analytics/presentation/analytics_screen.dart` | Cashflow overview, period selector, category percentages |
| 12 | **Trips** | `mobile/lib/features/trips/presentation/trips_screen.dart` | Active/Past trip cards, member counts, individual net balance |
| 13 | **Trip Details** | `mobile/lib/features/trips/presentation/trip_details_screen.dart` | Destination hero banner, members list, quick trip tabs |
| 14 | **Trip Itinerary** | `mobile/lib/features/trips/presentation/trip_itinerary_screen.dart` | Day-by-day plan tabs, activities timeline with times & costs |
| 15 | **Group Expenses** | `mobile/lib/features/group_expenses/presentation/group_expenses_screen.dart` | Shared expense feed, multi-payer summary, per-person shares |
| 16 | **Add Group Expense** | `mobile/lib/features/group_expenses/presentation/add_group_expense_screen.dart` | Multi-payer entry (e.g. A ₹400, C ₹160), sum validation |
| 17 | **Split Expense** | `mobile/lib/features/group_expenses/presentation/split_expense_screen.dart` | Equal / Custom / Percentage splits, participant toggles |
| 18 | **Balances & Settlements** | `mobile/lib/features/settlements/presentation/balances_screen.dart` | Net group standings, Debt Minimizer optimal payment plan |
| 19 | **Settlement Details** | `mobile/lib/features/settlements/presentation/settlement_details_screen.dart` | Direct UPI QR code, payment links, settlement verification |
| 20 | **AI Financial Assistant** | `mobile/lib/features/ai_assistant/presentation/ai_assistant_screen.dart` | Conversational financial insights & trip budget advisor |
| 21 | **Receipt Scanner** | `mobile/lib/features/receipts/presentation/receipt_scanner_screen.dart` | Camera viewfinder overlay, OCR line item parser |
| 22 | **Recurring Expenses** | `mobile/lib/features/recurring/presentation/recurring_expenses_screen.dart` | Monthly commitments card, active subscriptions timeline |
| 23 | **Notifications** | `mobile/lib/features/notifications/presentation/notifications_screen.dart` | Trip expense alerts, debt settlement requests, reminders |
| 24 | **Profile and Settings** | `mobile/lib/features/profile/presentation/profile_screen.dart` | Preferences, Dark Mode switch, biometric, export data |

---

## 🛠 Tech Stack

### Frontend
- **Framework**: Flutter (Dart `^3.3.0`)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: GoRouter (`go_router`) with ShellRoute bottom navigation
- **Networking**: Dio (`dio`) with auth & retry interceptors
- **Real-Time**: Socket.IO client (`socket_io_client`)
- **Offline Storage**: Flutter Secure Storage & SharedPreferences
- **Design Language**: Apple-inspired styling, Hanken Grotesk typography, `#16A878` Emerald theme

### Backend
- **Runtime**: Node.js (`v20+` / `v24+`) + Express.js + TypeScript
- **Database**: MongoDB Atlas with Mongoose schemas & indexes
- **Validation**: Zod schema validation
- **Authentication**: JWT token pair + Phone OTP authentication
- **Real-Time Communication**: Socket.IO server with room dispatch
- **Security**: Helmet, CORS, express-rate-limit

---

## 🚀 Getting Started

### 1. Prerequisites
- Node.js `v20.x` or later
- npm `v10.x` or later
- Git

### 2. Backend Setup
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Start development server
npm run dev
```

The API will be operational at: `http://localhost:5000/api/v1`  
Health check endpoint: `http://localhost:5000/api/v1/health`

To run tests:
```bash
npm test
```

To build production TypeScript bundle:
```bash
npm run build
```

---

## ☁️ Building Flutter APK Without Local Flutter SDK (RAM-Friendly)

To conserve local machine RAM and disk space, **Flutter does not need to be installed on your local machine**. 

A complete GitHub Actions CI/CD workflow is included at [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml).

### How to Build the APK in GitHub's Cloud:
1. Commit and push the repository to GitHub:
   ```bash
   git add .
   git commit -m "feat: complete SpendMate full-stack implementation"
   git push origin main
   ```
2. Navigate to your repository's **Actions** tab on GitHub.
3. The **"Flutter Mobile CI & Build APK"** workflow will trigger automatically.
4. GitHub Actions will:
   - Check out code and set up Java 17 + Flutter SDK 3.29.0 on Ubuntu.
   - Run `dart format` and `flutter analyze`.
   - Run test suite.
   - Compile the Android APK via `flutter build apk --debug`.
   - Upload the resulting **`spendmate-debug-apk`** artifact for direct download to your phone!

---

## 💡 Multi-Payer Split & Settlement Logic

### Example Scenario (from prompt):
- **Expense**: Shuttle Tickets = ₹560.00 (`56000` paise)
- **Contributors**:
  - Aarav paid ₹400.00 (`40000` paise)
  - Rohan paid ₹160.00 (`16000` paise)
- **Shared equally among 4 friends**: ₹140.00 (`14000` paise) each.

### Balances & Debt Minimizer Resolution:
- **Aarav** receives ₹960 (`+96000` paise)
- **Kunal** receives ₹160 (`+16000` paise)
- **Rohan** owes ₹480 (`-48000` paise)
- **Pooja** owes ₹640 (`-64000` paise)

The **Debt Minimizer** algorithm computes exactly **3 minimal payment transfers**:
1. **Pooja** pays **Aarav** ₹480
2. **Rohan** pays **Aarav** ₹480
3. **Pooja** pays **Kunal** ₹160

All group debts are resolved with minimum transaction overhead.

---

## 📄 License
ISC License © 2026 SpendMate Team.
