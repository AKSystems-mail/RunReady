# RunReady 🏃

A Flutter app that generates AI-powered running routes using Gemini and Google Maps.

## Features

- **AI route generation** — Describe your ideal run (distance, loop vs point-to-point, local vs explorer mode) and Gemini 3.5-flash produces a custom route with turn-by-turn directions
- **Map previews** — Embedded Google Maps directions view for each generated route
- **Weather-aware** — Gemini checks current weather, sunrise/sunset, and flags whether conditions are comfortable for running
- **Active run tracking** — Follow your route with a live map during the run
- **History & stats** — Saved routes and run statistics

## APIs Required

| Service | What for |
|---------|----------|
| **Gemini API** | Route generation & weather scouting (`gemini-3.5-flash`) |
| **Google Maps Embed API** | Map previews in route cards and active run screen |
| **Geolocator (device GPS)** | Current location detection (no API key needed) |

## Getting Started

### Prerequisites

- Flutter SDK (compatible with Dart 3.7+)
- Google Cloud project with Maps Embed API enabled
- Gemini API key

### Setup

```bash
# 1. Clone and enter the project
git clone <repo-url>
cd run_ready

# 2. Set up API keys
cp lib/config/env.dart.example lib/config/env.dart
# Edit lib/config/env.dart with your real keys

# 3. Run
flutter run

# 4. Build APK
flutter build apk --release
```

### API Key Setup

1. **Gemini API key** — Get one at https://aistudio.google.com/apikey
2. **Google Maps Embed API key** — Enable "Maps Embed API" in your Google Cloud Console

## Project Structure

```
lib/
├── config/          # API keys (env.dart — gitignored)
├── models/          # RouteData, Preferences, WeatherInfo, etc.
├── providers/       # Riverpod state management
├── screens/         # Home, ActiveRun, History, Stats
├── services/        # GeminiService (route generation)
└── widgets/         # RouteCard, WeatherWidget
```

## Tech Stack

- **Flutter** with Dart 3.7+
- **Riverpod** for state management
- **google_generative_ai** — Gemini API Dart SDK
- **webview_flutter** — Google Maps embed rendering
- **geolocator** — GPS position
- **go_router** — navigation
- **shared_preferences** — local persistence
