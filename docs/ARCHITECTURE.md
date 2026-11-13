# SpendMate System Architecture & Engineering Specifications

SpendMate is an Apple-inspired mobile application for personal expense tracking and multi-payer group trip settlements.

---

## 1. Monorepo Organization

```
spendmate/
├── backend/                  # Node.js + Express + TypeScript + Mongoose + Socket.IO
│   ├── src/
│   │   ├── config/           # Database, environment, and constants
│   │   ├── common/           # Error handling, middleware, standard responses, logger
│   │   ├── modules/
│   │   │   ├── auth/         # Phone OTP & JWT authentication
│   │   │   ├── users/        # User profiles, currency, theme settings
│   │   │   ├── wallets/      # Cash, Bank, Credit Card, and UPI accounts
│   │   │   ├── categories/   # System & user-defined categories
│   │   │   ├── transactions/ # Inflow & outflow tracking with integer paise
│   │   │   ├── budgets/      # Monthly category targets & alert thresholds
│   │   │   ├── savings/      # Savings goals & deposits
│   │   │   ├── analytics/    # Cashflow, spending velocity & trends
│   │   │   ├── trips/        # Trips & member roles
│   │   │   ├── trip_expenses/# Multi-payer expense records
│   │   │   ├── settlements/  # Debt Minimizer algorithm & payment reconciliation
│   │   │   ├── itineraries/  # Day-wise trip activities
│   │   │   ├── receipts/     # OCR parsing
│   │   │   ├── ai_assistant/ # Financial advisory engine
│   │   │   ├── recurring_expenses/ # Recurring subscriptions
│   │   │   ├── notifications/ # User notifications
│   │   │   └── sync/         # Delta offline synchronization
│   │   ├── server.ts
│   │   └── app.ts
├── mobile/                   # Flutter Application (Dart)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/        # Apple-inspired typography, light/dark themes, color tokens
│   │   │   ├── constants/    # API endpoints & constants
│   │   │   ├── network/      # Dio client, interceptors & token refresh
│   │   │   ├── storage/      # Secure encrypted storage
│   │   │   ├── database/     # Offline sync queue manager
│   │   │   ├── widgets/      # Reusable Apple-styled cards, buttons, badges, currency text
│   │   │   └── router/       # GoRouter & 5-tab bottom navigation shell
│   │   ├── features/         # 16 domain feature modules implementing all 24 Stitch screens
│   │   └── main.dart
├── .github/workflows/
│   ├── flutter_ci.yml        # Cloud CI for Dart analysis, tests, and Android APK builds
│   └── backend_ci.yml        # TypeScript build check and Jest test execution
├── docs/                     # Architecture & API documentation
├── DEVELOPMENT_STATUS.md     # Phase checklist & implementation log
└── README.md
```

---

## 2. Design System & Stitch Screen Token Mapping

All screens strictly follow the Google Stitch Project `7940772611928863336`:

| Token | Hex Value | Purpose |
| :--- | :--- | :--- |
| **Primary** | `#16A878` | Emerald brand color, active tabs, confirmed balances |
| **Secondary** | `#00A878` | Gradient accents and high-priority actions |
| **Blue** | `#4388FF` | Travel pillars, trips, flights |
| **Purple** | `#8B5CF6` | AI assistant, recurring subscriptions |
| **Coral** | `#FF6B6B` | Negative debts, outflows, warnings |
| **Orange** | `#FFA94D` | Pending states, budget alerts |
| **Light Background** | `#F7F8FA` | Neutral Apple-inspired app background |
| **Light Card** | `#FFFFFF` | Inset card surfaces |
| **Light Border** | `#E9EDF2` | Subtle 1px separation lines |
| **Dark Background** | `#10131A` | OLED dark mode background |
| **Dark Card** | `#191E28` | Elevated dark card surfaces |
| **Dark Border** | `#292F3A` | Dark border dividers |

---

## 3. Financial Precision & Integer Paise Arithmetic

Floating-point representations (`0.1 + 0.2 = 0.30000000000000004`) lead to accumulated financial discrepancies. SpendMate mandates **integer paise**:
- ₹1.00 = `100` paise
- ₹560.00 = `56000` paise
- Remainder distribution: If splitting `10000` paise (₹100) among 3 people:
  - Base share: `floor(10000 / 3) = 3333` paise
  - Remainder: `10000 % 3 = 1` paise
  - Participant 1 pays `3334` paise, Participants 2 & 3 pay `3333` paise.
  - Sum is strictly conserved: `3334 + 3333 + 3333 === 10000`.

---

## 4. Multi-Payer Group Split & Debt Minimizer Algorithm

### Mathematical Formulation
Let $N$ be the set of members in a group trip.
For any group expense $E$, contributors $P \subseteq N$ pay amounts $c_i$ such that:
$$\sum_{i \in P} c_i = \text{Amount}(E)$$
Participants $S \subseteq N$ share the expense with individual portions $s_j$ such that:
$$\sum_{j \in S} s_j = \text{Amount}(E)$$

Each member's net balance $B_k$ is defined by:
$$B_k = \sum \text{Contributed}_k - \sum \text{Shared}_k$$
- If $B_k > 0$, member $k$ is a **creditor** (is owed money).
- If $B_k < 0$, member $k$ is a **debtor** (owes money).
- $\sum_{k \in N} B_k = 0$ is guaranteed.

### Minimal Transaction Settlement Proof
The standard bilateral settlement graph has up to $\binom{N}{2} = O(N^2)$ transactions.
Using our greedy Debt Minimizer algorithm:
1. Max-heap of debtors $D$ (sorted descending by $|B_k|$)
2. Max-heap of creditors $C$ (sorted descending by $B_k$)
3. Pop top debtor $d$ and creditor $c$.
4. Transfer $T = \min(|B_d|, B_c)$.
5. Update balances and repeat until all are 0.
This guarantees resolution in at most $N - 1$ transactions!

#### Worked Example:
- **A** receives ₹960 (+96000 paise)
- **B** receives ₹160 (+16000 paise)
- **C** owes ₹480 (-48000 paise)
- **D** owes ₹640 (-64000 paise)

Optimal Settlement:
1. **D** pays **A** ₹480 (48000 paise)
2. **C** pays **A** ₹480 (48000 paise) [A is now settled: $96000 - 48000 - 48000 = 0$]
3. **D** pays **B** ₹160 (16000 paise) [B & D are both settled]
Total transactions: exactly **3 payments**, fully settling 4 people.
