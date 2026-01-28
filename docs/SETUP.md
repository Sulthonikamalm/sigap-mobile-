# Setup Guide

## 🎯 Quick Start

### 1. Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

### 2. Backend (Golang)

```bash
cd backend
go mod download
go run cmd/server/main.go
```

---

## 📱 Frontend Setup (Detailed)

### Prerequisites:
- Flutter SDK 3.x
- Android Studio / Xcode
- Firebase account

### Steps:

#### 1. Install Flutter
```bash
# Check installation
flutter doctor
```

#### 2. Get Dependencies
```bash
cd frontend
flutter pub get
```

#### 3. Firebase Setup (When Ready)
1. Create Firebase project: https://console.firebase.google.com
2. Add Android app
3. Download `google-services.json` → `android/app/`
4. Add iOS app
5. Download `GoogleService-Info.plist` → `ios/Runner/`

#### 4. Run App
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web (for testing)
flutter run -d chrome
```

---

## 🖥️ Backend Setup (Detailed)

### Prerequisites:
- Go 1.21+
- Firebase Admin SDK credentials (optional)

### Steps:

#### 1. Install Go
```bash
# Check installation
go version
```

#### 2. Get Dependencies
```bash
cd backend
go mod download
```

#### 3. Environment Setup
```bash
cp .env.example .env
# Edit .env with your configuration
```

#### 4. Firebase Admin SDK (When Ready)
1. Go to Firebase Console → Project Settings → Service Accounts
2. Generate new private key
3. Save as `config/firebase-admin-sdk.json`
4. Set environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="config/firebase-admin-sdk.json"
```

#### 5. Run Server
```bash
go run cmd/server/main.go
```

#### 6. Test
```bash
curl http://localhost:8080/health
```

---

## 🔗 Integration

### Flutter → Firebase (Direct)
```dart
// Firebase operations (primary)
await FirebaseFirestore.instance
  .collection('locations')
  .add(locationData);
```

### Flutter → Golang (Optional)
```dart
// API calls (for heavy logic)
final response = await http.get(
  Uri.parse('http://localhost:8080/api/nearby')
);
```

---

## 🐳 Docker (Optional)

### Backend:
```bash
cd backend
docker build -t sigap-backend .
docker run -p 8080:8080 sigap-backend
```

---

## 🚀 Deployment

### Frontend (APK):
```bash
cd frontend
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

### Backend (Server):
- Deploy to: Railway, Render, Fly.io, or VPS
- Use Docker for easy deployment

---

## 📝 Next Steps

1. ✅ Setup complete
2. ⏳ Configure Firebase
3. ⏳ Implement authentication
4. ⏳ Add location tracking
5. ⏳ Build panic button feature

---

**Need help?** Check [ARCHITECTURE.md](ARCHITECTURE.md)
