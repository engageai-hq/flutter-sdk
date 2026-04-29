# EngageAI Flutter SDK

Add an AI-powered voice and text assistant to any Flutter app. Users speak or type what they want — EngageAI calls your app's functions to make it happen.

> **What you build with this:** A "Hey, what's my balance?" or "I want jollof rice from somewhere nearby" voice/text assistant inside your existing Flutter app, without building any AI infrastructure yourself.

## Install

In your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  rive: ^0.14.0
  engageai_sdk:
    git:
      url: https://github.com/engageai-hq/flutter-sdk
      ref: v0.2.0
```

Then:

```bash
flutter pub get
```

## Quick start

```dart
import 'package:engageai_sdk/engageai_sdk.dart';
import 'package:rive/rive.dart' hide Animation;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init(); // required for the animated character
  runApp(const MyApp());
}

final engageAI = EngageAI(
  config: EngageAIConfig(
    serverUrl: 'https://engageai-sdk-production.up.railway.app',
    appId: 'your_app_id',          // from dashboard.engageai.tech
    apiKey: 'eai_...',             // from your portal's API Keys page
    appName: 'YourApp',
    domain: 'fintech',
  ),
);

engageAI.registerFunctions([
  AppFunction(
    name: 'get_balance',
    description: 'Get the current account balance',
    parameters: {'type': 'object', 'properties': {}},
    handler: (params) async => {'balance': 5000, 'currency': 'NGN'},
  ),
]);

await engageAI.initialize();
```

Then drop the voice button anywhere in your widget tree:

```dart
EngageCharacterFab(
  engageAI: engageAI,
  voiceService: EngageVoiceService(
    config: engageAI.config,
    voice: 'nova',
  ),
)
```

That's it. Your app now has a voice assistant that can call any of your registered functions.

## Documentation

Full developer docs (configuration, function patterns, voices, confirmation flows, troubleshooting): **https://dashboard.engageai.tech/docs**

## Get an API key

1. Sign up at https://dashboard.engageai.tech
2. Create an app
3. Generate an API key
4. Define your functions (in code via `registerFunctions(...)`, or visually in the portal)

The free tier includes 500 credits per month — enough to integrate, test, and ship to a small beta.

## What's in this repo

This is a published mirror of the Flutter SDK source. Active development happens in the EngageAI monorepo; this repo is updated from there at each release.

```
lib/
├── engageai_sdk.dart                 # public exports
└── src/
    ├── core/                         # main EngageAI class + config
    ├── models/                       # AppFunction, AgentAction, etc.
    ├── services/                     # API client, audio, streaming, voice
    └── widgets/                      # EngageCharacterFab, chat widgets
assets/
└── character/character.riv           # animated character (Rive file)
```

## Versioning

We use [SemVer](https://semver.org). Pin to a specific tag (`ref: v0.2.0`) for production apps; track `main` only if you're comfortable with breaking changes.

Current version: `0.2.0` (early — interfaces may change before 1.0).

## License

MIT — see [LICENSE](./LICENSE).

## Support

- Issues: https://github.com/engageai-hq/flutter-sdk/issues
- Email: help@engageai.tech
- Status: https://engageai.tech (subscribe via the footer for incident emails)
