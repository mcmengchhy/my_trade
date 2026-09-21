# Trade Journey — Check-in App Feature Summary & Improvement Structure

## Executive Overview
**Trade Journey** (`task_game`) is a Flutter productivity & trading-discipline coach mobile application. It enables users to set compounding trading challenges (e.g., "$10 to $1,000 in 20 days"), maintain trading discipline through custom rules, log daily trades along with emotional/strategy reflections, and visually track their progress.

---

## 1. What We Currently Have (Current State Analysis)

### 🏗️ Architecture & Tech Stack
- **Framework**: Flutter 3.x (Dart SDK `^3.9.2`)
- **State Management**: `Provider` (`MultiProvider`, `ChangeNotifierProvider`)
- **Persistence**: `SharedPreferences` storing JSON-encoded state (`StorageService`)
- **Charts & Visualization**: `fl_chart` (compounding growth line chart), custom heatmap widget (`ActivityHeatmap`)
- **Theme**: Material 3 with dark/light mode support (`AppPalette` & `AppTheme`)

### 🧩 Core Data Models
1. **`UserProfile`** (`lib/models/user_profile.dart`): User name, account creation timestamp.
2. **`Challenge`** (`lib/models/challenge.dart`):
   - Goal parameters: `id`, `name`, `startBalance`, `targetBalance`, `durationDays`, `startDate`, `endDate`, `currentBalance`.
   - Rules & Constraints: `rules` (`List<String>`), `maxDailyLossPct` (`double?`).
   - Trade Log: `trades` (`List<TradeEntry>`).
3. **`TradeEntry`** (`lib/models/trade_entry.dart`):
   - Trade execution details: `date`, `pnl`, `instrument`, `direction` ('long' | 'short'), `entryPrice`, `exitPrice`, `size`, `stopLoss`, `takeProfit`.
   - Strategy & Setup: `setup` ('Breakout', 'Pullback', 'Reversal', 'Trend continuation', 'Other').
   - Psychological & Discipline: `emotion` ('Calm', 'Neutral', 'Fear', 'Excited', 'Angry', 'Revenge', 'FOMO'), `followedPlan` (`bool?`), `lesson`, `note`.

### 📊 Business Logic & Calculation Engines
- **Compounding Math (`lib/utils/challenge_math.dart`)**:
  - `requiredDailyRate`: Compounding growth rate required per day to hit target balance.
  - `expectedBalance`: Pace target for any given day.
  - `todaysRequiredProfit`: Net profit target for current day.
  - `paceStatus`: Compares actual balance vs expected compounding curve (`ahead`, `onTrack`, `behind`).
  - `statusForDay`: Evaluates daily outcome (`profit`, `loss`, `breakeven`, `noActivity`, `future`).
  - `dailyLossBreached`: Triggers alert if day's net loss exceeds starting balance percentage limit.
  - `currentProfitStreak`: Consecutive profit days up to latest activity date.
  - `planAdherence`: Percentage of trades where user adhered to their rules.
- **Performance Analytics (`lib/utils/performance_stats.dart`)**: Win Rate %, Profit Factor, Average Win $, Average Loss $, Best Trade, Worst Trade.
- **Risk Math (`lib/utils/trade_math.dart`)**: Real-time Risk Amount ($) and Risk:Reward ratio calculation.

### 📱 User Interface & Screens
- **`WelcomeScreen`**: Staggered entrance animation, onboarding flow, name entry.
- **`DashboardScreen`**: Main overview showing active/completed challenges, status counts, profile entry, empty state.
- **`ChallengeFormScreen`**: Creation form with 20-day, 30-day, or custom duration presets, max daily loss limit %, preset & custom discipline rules, live required rate calculation preview.
- **`ChallengeDetailScreen`**:
  - Goal balance & progress indicator bar.
  - Daily required profit & Pace indicator badge (`Ahead`, `On track`, `Behind`).
  - Daily loss limit breach warning banner.
  - Trading rules section.
  - Growth vs Target compounding line chart (`BalanceChart`).
  - Daily Activity Heatmap timeline (`ActivityHeatmap`).
  - Discipline & Performance grid (Win Rate, Profit Factor, Plan Adherence, Avg Win/Loss).
  - Logged trades list with deletion support.
- **`AddTradeScreen`**: Trade journal form with setup dropdown, instrument, direction, prices, SL/TP, PnL, plan adherence toggle ("Did you follow your plan?"), emotion chips, lesson learned box, notes.
- **`ProfileScreen`**: Editable user profile name, trading start date, overall stats across all challenges (total challenges, active, achieved, net cumulative P/L).

---

## 2. Detailed Assessment of the "Check-in" Feature

### Current Implementation
In the current application codebase, **Check-in** is **implicitly integrated within trade logging**:
1. Users interact with the **`ActivityHeatmap`** horizontal timeline strip.
2. Tapping a day cell opens the **`AddTradeScreen`** pre-filled with that date.
3. Logging a trade updates the day cell's status color:
   - 🟢 **Green**: Profit day (intensity proportional to required daily growth)
   - 🔴 **Red**: Loss day
   - 🟡 **Yellow**: Breakeven
   - 🔘 **Slate Gray**: No activity logged
   - ⚪ **Faded**: Future days
4. Trade journal records discipline metrics (**Plan Adherence** + **Emotion Tagging**).

### Key Strengths
- ✅ Clean, single-row horizontal daily timeline heatmap tailored for 20-30 day challenges.
- ✅ Psychological journaling (tracking FOMO, Revenge, Calm, and lessons learned).
- ✅ Live daily target tracking and rule violation warnings.

---

## 3. What We Need to Improve (Gap Analysis & Detailed Roadmap)

### 🛠️ Priority 1: Automated Test Maintenance
- **Fix `test/welcome_flow_test.dart`**:
  - Update expected text assertion from `'Trade Challenges'` to `'Trade Journey'` to match current UI design and resolve test suite failure.

### 🎯 Priority 2: Dedicated Daily Check-in Mechanism
1. **Support "Disciplined No-Trade Day" Check-ins**:
   - *Current issue*: A day with 0 trades is labeled `noActivity`. However, refraining from trading when no setups exist is a **key discipline victory**.
   - *Improvement*: Introduce a explicit **Daily Check-in Flow** allowing users to check in as "No Trade Day — Rules Followed". Add a new `DayStatus.disciplinedNoTrade` status represented by a distinct color badge (e.g. Teal/Blue).
2. **Pre-Market & Post-Market Routine**:
   - **Pre-Market Check-in**:
     - Mindset score (1-5 stars)
     - Rule commitment acknowledgment
     - Daily max loss limit reminder
   - **Post-Market / Evening Wrap-up**:
     - Did you follow all trading rules today?
     - End-of-day reflection journal
     - Daily discipline rating
3. **Dedicated Check-in Streak**:
   - *Current issue*: `currentProfitStreak` only counts profitable trade days. A loss day resets it.
   - *Improvement*: Implement a **Check-in & Discipline Streak** counting consecutive days where the user completed their daily check-in (whether trading or resting disciplined).

### 🎮 Priority 3: Gamification & Engagement ("Task Game" Concept)
1. **XP & Level Progression System**:
   - Award XP for daily activities:
     - Daily Check-in: +50 XP
     - Logging trade with reflection lesson: +100 XP
     - 100% Plan Adherence on a trade: +150 XP
     - Disciplined No-Trade Day: +100 XP
   - User levels (e.g., Level 1 "Novice Trader", Level 5 "Disciplined Trader", Level 10 "Master Trader").
2. **Badges & Achievements System**:
   - 🏆 *Rule Follower*: 10 trades logged with 100% plan adherence.
   - 🛡️ *Shield of Discipline*: 5 consecutive days without breaching max daily loss.
   - 🔥 *Streak Master*: 7-day Check-in Streak.
   - 🧘 *Zen Trader*: 5 trades logged with "Calm" emotion.
3. **Daily Discipline Score**:
   - Aggregate daily score (0–100%) incorporating plan adherence, rule compliance, and emotion control.

### 🔔 Priority 4: Notifications & Reminders
1. **Local Daily Push Notifications**:
   - Morning notification: "Set your daily mindset & review your trading rules."
   - Evening notification: "Time for your daily trading check-in & journal review."

### 📈 Priority 5: Analytics & Emotion Insights
1. **Emotion Impact Chart**:
   - Analytics widget showing Net PnL grouped by emotion tag (e.g., total PnL from "FOMO" trades vs. "Calm" trades).
2. **Rule Violation Summary**:
   - Breakdown of which rules are broken most frequently.
3. **Data Export & Backup**:
   - Export trade logs and journal notes to CSV or JSON format.

---

## 4. Feature Matrix Overview

| Feature Category | Current State | Proposed Improvement | Priority |
| :--- | :--- | :--- | :--- |
| **Check-in Type** | Implicit (via trade logging only) | Explicit Pre/Post Market Daily Check-in Modal | High |
| **No-Trade Days** | Labeled as "No Activity" | "Disciplined No-Trade Day" status with custom cell badge | High |
| **Streak Tracking** | Profit Streak only | Dual Streaks: Profit Streak + Discipline/Check-in Streak | High |
| **Test Suite** | 1 test failure in welcome flow | Fix string mismatch in `welcome_flow_test.dart` | High |
| **Gamification** | Challenge progress & status chips | XP System, Levels, Achievements & Badges | Medium |
| **Reminders** | None | Local scheduled notifications (Morning / Evening) | Medium |
| **Analytics** | Win rate, Profit factor, Avg win/loss | Emotion PnL breakdown & Rule failure statistics | Medium |

