## Purpose

**30 Juz' in 7 Days** is a simple tracker and reminder app that helps users complete the Qur'an in seven days.

The app does **not** contain Qur'an text, audio, tafsir, or a Qur'an reader.

Its purpose is simply to:

- give the user a daily portion;
- remind them about it;
- let them record whether they completed it;
- show their progress throughout the seven days.

## Religious foundation

The concept of completing the Qur'an in seven days is based on the guidance reported in **Sahih al-Bukhari 5052**, where the Prophet ﷺ instructed ʿAbdullah ibn ʿAmr to complete the Qur'an in seven days. The narration also reports that ʿAbdullah would recite one-seventh of the Qur'an during the daytime.

**Important:** The app should distinguish between:

1. **The seven-day completion** — established in the hadith.
2. **The particular seven-part division/schedule** we use in the app — a traditional division that should be documented separately rather than presented as though every detail was directly prescribed in Bukhari 5052.

## Challenge structure

A challenge consists of **7 days**.

Each day has one assigned portion of the Qur'an.

The user starts the challenge on a chosen date and progresses through the seven daily portions.

### Traditional seven-part schedule

**Day 1:** Al-Baqarah → An-Nisa

**Day 2:** Al-Ma'idah → At-Tawbah

**Day 3:** Yunus → An-Nahl

**Day 4:** Al-Isra → Al-Furqan

**Day 5:** Ash-Shu'ara → Ya-Sin

**Day 6:** As-Saffat → Al-Hujurat

**Day 7:** Qaf → An-Nas

The commonly cited pattern is:

**3 → 5 → 7 → 9 → 11 → 13 → Al-Mufassal**

This schedule should be treated as the **traditional division used for the seven-day khatmah**, not as a claim that these exact boundaries are stated in Bukhari 5052.

## Core user action

For each day's portion, the user can record:

**○ Not completed**

or

**✓ Completed — Alhamdulillah**

The app records the completion date and updates the user's overall progress.

## Product principle

> **The app is a companion for completing a seven-day khatmah — not a Qur'an-reading app.**
> 

Keep the experience simple, respectful, and free from unnecessary gamification.

user flow

# User Flow

## 1. First launch

User opens the app for the first time.

↓

Sees a simple introduction:

> **30 Juz' in 7 Days**
> 
> 
> Complete the Qur'an in seven days with a simple daily reminder and progress tracker.
> 

↓

**[ Start My 7-Day Khatmah ]**

---

## 2. Choose start date

User chooses when their 7-day challenge begins.

Default:

> **Today**
> 

Optional:

> Choose another date
> 

↓

**[ Continue ]**

---

## 3. Set reminder

User chooses a daily reminder time.

Example:

> **Remind me every day at:**
> 
> 
> 🕐 7:00 PM
> 

↓

The app requests notification permission.

↓

**[ Start Challenge ]**

---

## 4. Challenge begins

User arrives at the Home screen.

They see:

> **Day 1 of 7**
> 
> 
> Today's portion
> 
> **Al-Baqarah → An-Nisa**
> 
> **0 / 1 completed**
> 
> **[ Mark as completed ]**
> 

The user can open the app at any time to see today's target.

---

## 5. Daily reminder

At the selected time, the app sends a notification.

Example:

> **Your Qur'an reading for today is waiting.**
> 
> 
> Day 3 of 7 — Yunus → An-Nahl
> 

Tapping the notification opens the app.

---

## 6. User completes today's portion

User taps:

> **✓ Completed — Alhamdulillah**
> 

The app records the completion.

The Home screen updates:

> **Day 3 completed ✓**
> 

Overall progress updates as well.

---

## 7. User hasn't completed today's portion

If the user opens the app and hasn't completed today's portion:

> **Day 3 of 7**
> 
> 
> Today's portion
> 
> Yunus → An-Nahl
> 
> **Not completed yet**
> 
> [ Mark as completed ]
> 

No guilt, penalties, or negative messaging.

---

## 8. User misses a day

The next day, the app recognizes that yesterday wasn't completed.

Show:

> **Yesterday wasn't completed.**
> 
> 
> You have two options:
> 
> **[ Continue with today's portion ]**
> 
> **[ Adjust my remaining plan ]**
> 

We will define exactly how **Adjust my remaining plan** works in our next card.

---

## 9. Progress / history

User can view previous days:

> **Your 7-Day Journey**
> 
> 
> ✓ Day 1
> 
> ✓ Day 2
> 
> ✓ Day 3
> 
> ○ Day 4
> 
> ○ Day 5
> 
> ○ Day 6
> 
> ○ Day 7
> 

They can see which portions they completed.

---

## 10. Completion

After Day 7 is completed:

> **Alhamdulillah 🤍**
> 
> 
> **You completed your 7-day khatmah.**
> 
> 30 Juz' ✓
> 
> **[ Start Another Khatmah ]**
> 

The user can start a new 7-day challenge.

# **Core flow**

First Launch
↓
Start Challenge
↓
Choose Start Date
↓
Set Reminder
↓
Day 1
↓
Daily Reminder
↓
Mark Today's Portion Complete
↓
Next Day
↓
...
↓
Day 7
↓
Khatmah Complete

# Progress Rules

## 1. Daily completion

Each day has **one assigned Qur'an portion**.

The portion is either:

- **Not completed**
- **Completed**

The user marks it completed manually.

A portion is **not automatically considered completed** just because the day has ended.

---

## 2. Completion is permanent for that day

When the user taps:

> ✓ Completed — Alhamdulillah
> 

The day becomes completed.

The user should be able to **undo** this if they accidentally marked it completed.

Example:

> **Day 3 — Completed ✓**
> 
> 
> [Undo completion]
> 

---

## 3. Overall progress

Overall progress shows how many of the 7 daily portions the user has completed.

Example:

**3 / 7 portions completed — 43%**

Progress is independent from the calendar schedule. Missing a day does not erase previously completed portions.

However, the challenge itself always lasts **7 calendar days** from the chosen start date.

If a user misses a day, they become **behind schedule**, but the challenge does not automatically extend beyond the original 7 days.

---

## 4. Missing a day

If the user doesn't mark a day's portion as completed:

- The portion remains incomplete.
- The app does **not** delete or reset their progress.
- The next day's portion still becomes available.
- The user is informed that they have an unfinished previous portion.

Example:

> **Day 4**
> 
> 
> Yesterday's portion wasn't marked complete.
> 
> **1 portion remaining from Day 3**
> 

Then offer:

**[ Continue today's plan ]**

**[ Adjust my remaining plan ]**

---

## 5. Adjusting the remaining plan

If the user chooses to adjust their plan, the app calculates a new distribution of the **remaining portions across the remaining days**.

The user must confirm the new plan before it is applied.

Their already-completed portions are never changed.

---

## 6. Starting early

The user may read ahead, but **V1 should keep the daily schedule simple**.

For the first release:

> Today's portion is the portion being tracked.
> 

We don't need complicated "future-day completion" logic yet.

---

## 7. Finishing a day early

Once today's portion is marked completed:

> **Day 3 completed ✓**
> 

The user can continue reading if they want, but the app doesn't require or track additional reading for that day.

---

## 8. Completing the challenge

When all seven daily portions are completed:

> **7 / 7 days completed**
> 
> 
> **Alhamdulillah 🤍**
> 
> **Your 7-day khatmah is complete.**
> 

The user can then start another challenge.

---

# Core principle

> **The app tracks commitment and progress; it does not judge the user.**
> 

Missing a day doesn't mean the challenge is destroyed.

The user can continue, catch up, or adjust the remaining plan.

# Notification Behavior

## 1. Daily reminder

The user chooses a preferred reminder time during setup.

The app schedules a reminder for each day of the 7-day challenge.

Example:

> **Today's Qur'an portion is waiting.**
> 
> 
> Day 3 of 7 — Yunus → An-Nahl
> 

Tapping the notification opens the app.

---

## 2. Don't remind after completion

If the user has already completed today's portion, the app should **not send that day's reminder**.

---

## 3. Missed daily portion

If the user reaches the end of the day without completing the portion, the app may send **one gentle follow-up reminder**.

Example:

> **You still have today's portion remaining.**
> 
> 
> You have 2 days left in your 7-day khatmah.
> 

No aggressive or guilt-based messaging.

---

## 4. No excessive notifications

V1 should keep notifications intentionally minimal.

Maximum:

- One main daily reminder
- One optional follow-up reminder

The user should never feel spammed by the app.

---

## 5. Challenge completion

Once all seven portions are completed:

- Cancel remaining challenge reminders.
- Send a completion notification.

Example:

> **Alhamdulillah 🤍**
> 
> 
> You completed your 7-day khatmah.
> 

---

## 6. Challenge expiration

The challenge ends after **7 calendar days**, regardless of whether all portions were completed.

After the challenge ends:

- No further reminders are sent.
- The user can view their final result.
- The user can start another 7-day challenge.

---

## 7. Notification permission

The app should explain why notifications are useful **before requesting notification permission**.

Example:

> **Don't forget your daily portion**
> 
> 
> Allow reminders so we can help you stay on track during your 7-day khatmah.
> 

Then request permission.

If permission is denied, **the core app must still work normally**.

# V1 Scope

## V1 must include

### Challenge

- Start a 7-day khatmah
- Choose start date
- Follow the predefined 7-day schedule
- Automatically determine the current challenge day

### Daily tracking

- Show today's portion
- Mark today's portion as completed
- Undo completion
- Show completed/incomplete days
- Show overall progress

### Reminders

- Choose reminder time
- Daily reminder
- Optional follow-up reminder
- Stop reminders when the challenge ends or is completed

### Missed days

- Detect missed portions
- Show that the user is behind schedule
- Allow the user to continue
- Allow the user to adjust the remaining plan

### Completion

- Detect completion of all 7 portions
- Show a completion screen
- Allow starting another 7-day challenge

### Basic settings

- Reminder settings
- Restart/start a new challenge
- Basic app information
- Privacy information

---

# V1 must NOT include

- Qur'an text
- Qur'an audio
- Tafsir
- Translations
- User accounts
- Login/signup
- Cloud synchronization
- Social profiles
- Friends
- Leaderboards
- Chat
- AI
- Payments
- Subscriptions
- Advertising
- Complex analytics
- Multiple challenge types
- Custom reading schedules

---

# V1 Product Principle

> **Do one thing extremely well: help a person stay on track with a seven-day Qur'an completion.**
> 

Any feature that does not directly support this purpose should be considered for a future version rather than added to V1.

---

## V1 success criteria

The V1 is ready for release when a new user can:

> **Open app → understand the purpose → start a challenge → receive reminders → see today's portion → mark it completed → track progress → finish the seven days.**
> 

No account should be required.

The complete core experience should work without an internet connection after installation, except for anything that may technically require connectivity for store/service functionality.

# App Screens — V1

## 1. Welcome / Onboarding

Purpose: Explain the app in a few seconds and let the user start their 7-day khatmah.

Contains:

- App name
- Short explanation
- Start button

---

## 2. Challenge Setup

Purpose: Let the user configure the challenge before starting.

Contains:

- Start date
- Daily reminder time
- Notification permission
- Start challenge button

---

## 3. Home

Purpose: The main screen the user sees during their challenge.

Contains:

- Current day: Day X of 7
- Today's Qur'an portion
- Completion status
- Overall progress
- Days remaining
- Action to mark today's portion complete
- Information about missed/overdue portions when applicable

---

## 4. Progress / History

Purpose: Let the user see their journey through the seven days.

Contains:

- All 7 days
- Completed/incomplete status
- Overall progress
- Final result after the challenge ends

---

## 5. Settings

Purpose: Manage basic app preferences.

Contains:

- Reminder time
- Notifications on/off
- Restart/new challenge
- About
- Privacy information

---

## 6. Challenge Complete

Purpose: Celebrate completion and provide the next action.

Contains:

- Completion message
- 7/7 result
- Option to start another 7-day khatmah

---

# Navigation

The main navigation during an active challenge should be simple:

**Home | Progress | Settings**

Onboarding and setup happen before entering the main app.

Challenge completion can be shown from Home rather than necessarily being a permanent navigation item.

# Home Screen — V1

## Purpose

The Home screen is the primary screen during an active 7-day khatmah.

The user should immediately understand:

1. Which day of the challenge they're on.
2. What today's portion is.
3. Whether they completed today's portion.
4. How much progress they've made.

---

## Header

Show:

> **30 Juz' in 7 Days**
> 

And the current challenge day:

> **Day 3 of 7**
> 

Also show the number of days remaining.

Example:

> **4 days remaining**
> 

---

## Today's portion

Make this the main focus of the screen.

Example:

> **Today's Portion**
> 
> 
> **Yunus → An-Nahl**
> 

Optionally show the number of surahs:

> 7 surahs
> 

The app should not display Qur'an text.

---

## Completion action

If today's portion has not been completed:

Show a prominent button:

> **✓ Mark as completed**
> 

After the user taps it:

> **✓ Completed — Alhamdulillah**
> 

The button/state should make it obvious that the action succeeded.

The user should be able to undo the completion if it was accidental.

---

## Overall progress

Show progress toward the complete 7-day challenge.

Example:

> **3 / 7 days completed**
> 
> 
> `━━━━━━━━━━━━░░░░`
> 

> **43% complete**
> 

This represents completed daily portions, not simply the number of calendar days that have passed.

---

## Schedule preview

Show a compact view of the seven days.

Example:

> **Your Journey**
> 
> 
> ✓ Day 1
> 
> ✓ Day 2
> 
> ● Day 3 — Today
> 
> ○ Day 4
> 
> ○ Day 5
> 
> ○ Day 6
> 
> ○ Day 7
> 

The user can tap this to open the full Progress / History screen.

---

## Behind-schedule state

If the user has missed a previous day's portion, show a gentle notice.

Example:

> **You're behind by 1 portion**
> 
> 
> You have 3 days remaining.
> 
> **[ View options ]**
> 

Do not make this the dominant element of the screen.

---

## Completed-today state

After today's portion is completed, the Home screen should change to:

> **Alhamdulillah 🤍**
> 
> 
> **Today's portion completed**
> 
> Day 3 of 7 ✓
> 
> **Come back tomorrow for Day 4**
> 

The user can still view their progress.

---

# Home Screen Principle

> **One glance should be enough.**
> 

The user shouldn't have to navigate around the app to answer:

**"What am I supposed to do today?"**

# Progress / History Screen — V1

## Purpose

Give the user a clear view of their entire 7-day journey.

The screen should answer:

> **How am I doing with my 7-day khatmah?**
> 

---

## Overall progress

At the top, show:

> **Your 7-Day Journey**
> 

Then:

> **3 / 7 portions completed**
> 
> 
> **43% complete**
> 

The progress should be visually clear but simple.

---

## Seven-day timeline

Show all seven days in order.

Example:

> ✓ **Day 1**
> 
> 
> Al-Baqarah → An-Nisa
> 
> Completed
> 
> ✓ **Day 2**
> 
> Al-Ma'idah → At-Tawbah
> 
> Completed
> 
> ● **Day 3**
> 
> Yunus → An-Nahl
> 
> Today
> 
> ○ **Day 4**
> 
> Al-Isra → Al-Furqan
> 
> Upcoming
> 
> ○ **Day 5**
> 
> Ash-Shu'ara → Ya-Sin
> 
> Upcoming
> 
> ○ **Day 6**
> 
> As-Saffat → Al-Hujurat
> 
> Upcoming
> 
> ○ **Day 7**
> 
> Qaf → An-Nas
> 
> Upcoming
> 

---

## Statuses

Each day can have one of these states:

- **Completed**
- **Today**
- **Upcoming**
- **Missed**

The status should be immediately recognizable without relying only on color.

---

## Missed day

If a day was missed:

> **Day 2 — Missed**
> 
> 
> Al-Ma'idah → At-Tawbah
> 

The user should still be able to see it in their history.

A missed day does **not** erase previously completed portions.

---

## Active challenge

While the challenge is running, the current day should be visually emphasized.

Example:

> **● Day 3 — Today**
> 

The user should be able to tap a day to see its details.

---

## Completed challenge

After the seven-day period ends, show the final result:

> **Challenge Complete**
> 
> 
> **5 / 7 portions completed**
> 
> **71%**
> 

If all seven were completed:

> **Alhamdulillah 🤍**
> 
> 
> **7 / 7 portions completed**
> 
> **Khatmah complete**
> 

---

## Start another challenge

After the current challenge ends, provide:

> **[ Start Another 7-Day Khatmah ]**
> 

This starts a completely new challenge without deleting the previous result.

---

# Design Principle

> **Show progress without making the user feel judged.**
> 

The Progress screen is for reflection and motivation, not punishment.

# Settings & Challenge Management — V1

## Purpose

Provide only the settings necessary to control the user's challenge and reminders.

Keep this screen simple. It should not become a general-purpose settings page.

---

## Reminder settings

Show:

> **Daily Reminder**
> 

Allow the user to:

- Turn reminders on/off
- Change the reminder time

Example:

> 🔔 Daily reminder
> 
> 
> **7:00 PM**
> 
> [On]
> 

Changes should apply to future reminders.

---

## Challenge information

Show the current challenge:

> **Current Khatmah**
> 
> 
> Started: September 5
> 
> Ends: September 11
> 
> Day 1 of 7
> 

If there is no active challenge:

> **No active khatmah**
> 

---

## Start a new challenge

Allow the user to start another 7-day khatmah.

If an active challenge exists, show a confirmation first:

> **Start a new khatmah?**
> 
> 
> Your current challenge is still in progress. Starting a new one will end the current challenge.
> 

Buttons:

> **Cancel**
> 

> **Start New**
> 

Do not delete the previous challenge result unless we later decide to support challenge history.

---

## Restart current challenge

Allow the user to restart the current challenge if they genuinely want to start over.

Show confirmation:

> **Restart your khatmah?**
> 
> 
> Your current progress will be reset.
> 

Buttons:

> **Cancel**
> 

> **Restart**
> 

This action should be difficult to trigger accidentally.

---

## About

Show basic information:

> **30 Juz' in 7 Days**
> 
> 
> A simple companion for completing the Qur'an in seven days.
> 
> This app does not contain Qur'an text. It helps you track your daily portion and remember your commitment.
> 

---

## Privacy

Provide access to the app's privacy information.

Because V1 is designed to work without an account or personal data collection, keep the privacy experience simple and transparent.

---

# Settings Principle

> **Settings should support the challenge, not distract from it.**
> 

No unnecessary configuration in V1.


# Onboarding & Challenge Setup — V1

## Purpose

Introduce the app quickly and get the user into their first 7-day khatmah with minimal setup.

The onboarding should take **less than a minute**.

---

## Screen 1 — Welcome

Show:

> **30 Juz' in 7 Days**
> 

Short explanation:

> A simple companion to help you stay on track with a seven-day Qur'an khatmah.
> 

Then:

> **[ Start My Khatmah ]**
> 

No account creation.

No login.

---

## Screen 2 — Start Date

Ask:

> **When would you like to start?**
> 

Default:

> **Today**
> 

Allow the user to select a future date.

Do not allow a start date in the past for V1.

Then:

> **[ Continue ]**
> 

---

## Screen 3 — Daily Reminder

Ask:

> **When should we remind you?**
> 

Allow the user to select a daily reminder time.

Example:

> **7:00 PM**
> 

Explain briefly:

> We'll remind you about your daily portion during your seven-day journey.
> 

Then request notification permission.

If permission is denied, the user can still continue using the app.

---

## Screen 4 — Confirm

Before starting, show:

> **Your 7-Day Khatmah**
> 
> 
> Start: September 5
> 
> End: September 11
> 
> **Day 1**
> 
> Al-Baqarah → An-Nisa
> 
> Reminder: 7:00 PM
> 

Then:

> **[ Start Khatmah ]**
> 

---

## After starting

Take the user directly to the **Home screen**.

The user should immediately see today's portion and what they need to do.

---

# Onboarding Principles

- No account required.
- No unnecessary questions.
- No lengthy introduction.
- No Qur'an content.
- No forced notification permission.
- The user should reach their first daily portion as quickly as possible.

> **The goal of onboarding is to get the user started, not explain the entire app.**
> 

---

# Design Phase Checklist

After this card, the V1 screen structure is defined:

- Welcome
- Challenge Setup
- Home
- Progress / History
- Settings / Challenge Management
- Challenge Complete