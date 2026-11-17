# museum_brawijaya

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend API

The local backend defaults to port `3001`, matching `UAS_BACKEND`'s `PORT=3001`.
The Flutter app uses `http://10.0.2.2:<port>/api` on the Android emulator and
`http://localhost:<port>/api` on web and desktop. If the backend uses another
port, pass it when running Flutter, for example:

```sh
flutter run --dart-define=API_PORT=3002
```

For a different host or a complete API URL, set `API_BASE_URL`, for example
`--dart-define=API_BASE_URL=http://192.168.1.10:3001/api`. In backend development
mode, localhost web origins are allowed regardless of their frontend port.
