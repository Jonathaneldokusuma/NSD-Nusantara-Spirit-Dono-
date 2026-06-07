# NSD Flutter Client

Flutter client untuk Android, iOS, dan Web.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter build web
flutter build apk
```

API default:

- Flutter Web production di Firebase Hosting: set `API_URL` ke Railway
- Flutter Web development: `http://localhost:4000/api` melalui `--dart-define`
- iOS simulator: `http://localhost:4000/api`
- Android emulator: `http://10.0.2.2:4000/api`

Ganti endpoint dengan:

```bash
flutter run --dart-define=API_URL=https://api.example.com/api
```
