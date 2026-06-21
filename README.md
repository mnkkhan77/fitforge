# FitForge

**Offline Fitness & Nutrition Tracker — built for India 🇮🇳**

FitForge is a privacy-first Flutter app for tracking workouts and Indian-food
nutrition. Everything runs and stores locally on your device — no accounts, no
analytics, no third-party tracking. An optional AI coach can be enabled with
your own API key.

## Features

- **110+ exercises** (bodyweight + equipment) across five difficulty levels,
  each with step-by-step form cues and injury warnings.
- **5-day and 7-day training plans** that adapt sets and rest to your fitness
  level.
- **Live session tracker** with per-set tracking, rest timers, and haptic
  feedback.
- **Indian food library** (dal, roti, rice, paneer, eggs, chicken and more) with
  adjustable serving sizes and manual entry.
- **Macro tracking** against your active diet plan, with the day's log grouped by
  meal.
- **9 curated diet plans** for muscle gain, fat loss, and maintenance across veg,
  non-veg, and vegan preferences.
- **Body metrics & calorie targets** — enter weight, height, age and activity to
  get a Mifflin-St Jeor BMR/TDEE estimate and a goal-based calorie suggestion.
- **Progress tracking** — streak, consistency %, weekly charts, activity heatmap,
  and a weight trend.
- **Daily workout reminders** via local notifications (optional).
- **Optional AI coach** (Groq Llama 3.3) using your own key, stored encrypted.

## Privacy & Security

- All data is stored locally with `shared_preferences`.
- The AI API key is stored with Android Keystore encryption
  (`flutter_secure_storage`).
- HTTPS-only network traffic is enforced via `network_security_config.xml`.
- No analytics, no crash reporting, no third-party tracking.

## Getting started

```bash
flutter pub get
flutter run
```

To use the AI coach, open the **Coach** tab and paste a Groq API key
(`console.groq.com`). The key never leaves your device.

## Tech

Flutter · Provider · shared_preferences · flutter_secure_storage ·
flutter_local_notifications

## License

See [LICENSE](LICENSE).
