# Changelog

## 2.0.0 (2025-05-30)

### Added
- 110+ exercises (bodyweight + equipment) from Noob to Expert level
- 5-day and 7-day structured training plans that adapt sets and rest to your fitness level
- Live session tracker with per-set tracking, rest timers, and haptic feedback
- Indian food nutrition library (dal, roti, rice, paneer, eggs, chicken and more)
- Adjustable serving sizes and meal-grouped daily food log
- Full macro tracking matched against active diet plan
- 9 curated diet plans for muscle gain, fat loss, and maintenance (veg, non-veg, vegan)
- Body metrics (weight, height, age, activity) with Mifflin-St Jeor BMR/TDEE calorie targets
- Weight trend tracking over time
- Progress tracking: streak, consistency %, weekly charts, activity heatmap
- Optional daily workout reminders via local notifications
- Optional AI coach using Groq (user-provided key, stored encrypted)
- Persistent AI chat sessions with follow-up suggestions
- Daily food log that resets automatically at midnight
- Editable display name in profile
- Vibration toggle for workout haptics

### Security
- API key stored with Android Keystore encryption (flutter_secure_storage)
- HTTPS-only network traffic enforced via network_security_config.xml
- No analytics, no crash reporting, no third-party tracking
