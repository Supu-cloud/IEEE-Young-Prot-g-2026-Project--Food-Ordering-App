# Food Ordering System - Flutter App

Phase 1 of the IEEE Young Protege 2026 Food Ordering System mobile client.

## Included

- Feature-based architecture, shared wireframe-aligned design system and reusable UI components
- Dio API client with bearer-token interception
- Access token, refresh token and role storage through `flutter_secure_storage`
- Shared login plus customer, restaurant-owner and delivery-rider registration
- Session restoration, sign out and role-based navigation shells

Owner and rider registration creates a pending application, matching the backend API. These users can sign in after administrator approval.

## API configuration

The Android emulator development default is `http://10.0.2.2:5000/api`. Override it with compile-time Dart defines:

```shell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

For an iOS simulator use `http://127.0.0.1:5000/api`. For a physical device use the development machine's LAN address. Production builds should pass an HTTPS URL.

The client targets `E:\IEEE-Young-protege--Food-Ordering-Project-Backend-Repository` and currently integrates the login and three public signup endpoints.

## Windows note

Flutter plugins require Windows Developer Mode (or another setup that permits symbolic links). Enable it before running tests or a Windows build.
