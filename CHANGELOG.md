# Changelog

## 2.0.0 (2025-05-30)

### Added
- 110+ exercises (bodyweight + equipment) from Noob to Expert level
- 5-day and 7-day structured training plans
- Live session tracker with per-set tracking, rest timers, and haptic feedback
- Indian food nutrition library (dal, roti, rice, paneer, eggs, chicken and more)
- Full macro tracking matched against active diet plan
- 8 curated diet plans for muscle gain, fat loss, and maintenance
- Progress tracking: streak, consistency %, weekly charts, activity heatmap
- Optional AI coach using Groq or OpenAI (user-provided key, stored encrypted)
- Persistent AI chat sessions with follow-up suggestions
- Daily food log that resets automatically at midnight
- Editable display name in profile
- Vibration toggle for workout haptics

### Security
- API key stored with Android Keystore encryption (flutter_secure_storage)
- HTTPS-only network traffic enforced via network_security_config.xml
- No analytics, no crash reporting, no third-party tracking
