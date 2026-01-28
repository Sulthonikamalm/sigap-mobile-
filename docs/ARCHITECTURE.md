# Architecture Overview

## 🏗️ System Design

### Hybrid Architecture: Flutter + Firebase + Golang

```
┌─────────────────────────────────────────┐
│           Flutter Mobile App            │
│  (User Interface & Primary Logic)       │
└───────────┬─────────────────────────────┘
            │
            ├──────────────┬──────────────┐
            │              │              │
            ▼              ▼              ▼
    ┌──────────────┐ ┌──────────┐ ┌──────────┐
    │   Firebase   │ │  Golang  │ │  Device  │
    │   Services   │ │  Backend │ │  Sensors │
    └──────────────┘ └──────────┘ └──────────┘
```

---

## 🔥 Firebase (Primary Database)

### Services Used:
1. **Authentication**
   - Email/Password
   - Google Sign-In
   - Phone Auth

2. **Firestore**
   - User profiles
   - Location data (real-time)
   - Panic alerts
   - Chat messages

3. **Cloud Messaging (FCM)**
   - Push notifications
   - Panic alerts

4. **Storage**
   - Profile pictures
   - Evidence photos

### Why Firebase Primary?
- ✅ Real-time sync
- ✅ Offline support
- ✅ Built-in security rules
- ✅ Scalable
- ✅ **App works without backend server**

---

## 🐹 Golang Backend (Optional Enhancement)

### Purpose:
Handle **heavy computations** that shouldn't run on mobile:

1. **Nearby Users Algorithm**
   - Haversine distance calculation
   - Geospatial queries
   - Clustering

2. **Analytics**
   - Pattern detection
   - Safety score calculation
   - Heatmap generation

3. **AI/ML Processing**
   - Sentiment analysis
   - Risk assessment
   - Anomaly detection

### Why Optional?
- ✅ App fully functional with Firebase only
- ✅ Backend adds **advanced features**
- ✅ Can be deployed later
- ✅ Fail-safe: App continues if backend down

---

## 📊 Data Flow

### Scenario 1: Normal Operation (Firebase Only)
```
User → Flutter → Firebase → Other Users
```

### Scenario 2: With Backend (Enhanced)
```
User → Flutter → Firebase → Golang → Firebase → Other Users
                    ↓
              (Real-time sync)
```

### Scenario 3: Backend Down (Fail-safe)
```
User → Flutter → Firebase → Other Users
(Backend bypassed, app still works)
```

---

## 🔐 Security

### Firebase Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Location data (with privacy)
    match /locations/{locationId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

### Backend Security:
- Firebase token verification
- API key authentication
- Rate limiting

---

## 📱 Flutter Architecture

### State Management:
- **Provider** (recommended for simplicity)
- Alternative: Bloc, Riverpod

### Folder Structure:
```
lib/
├── core/           # Core utilities
├── services/       # Business logic
├── providers/      # State management
└── features/       # Feature modules
```

---

## 🖥️ Golang Architecture

### Framework:
- **Fiber** (Express-like, fast)

### Folder Structure:
```
backend/
├── cmd/            # Entry points
├── internal/       # Private code
├── config/         # Configuration
└── pkg/            # Public libraries
```

---

## 🚀 Deployment Strategy

### Phase 1: MVP (Firebase Only)
- Deploy Flutter app (APK)
- No backend needed
- **Fastest to market**

### Phase 2: Enhanced (+ Golang)
- Deploy backend to Railway/Render
- Add advanced features
- **Better performance**

### Phase 3: Scale
- Multiple backend instances
- Load balancing
- CDN for assets

---

## 🔄 Communication Patterns

### 1. Real-time (Firebase)
```dart
// Listen to location updates
FirebaseFirestore.instance
  .collection('locations')
  .snapshots()
  .listen((snapshot) {
    // Update UI
  });
```

### 2. REST API (Golang)
```dart
// Call backend for heavy computation
final response = await http.post(
  Uri.parse('$baseUrl/api/nearby'),
  body: json.encode(locationData),
);
```

### 3. Push Notifications (FCM)
```dart
// Receive panic alerts
FirebaseMessaging.onMessage.listen((message) {
  // Show notification
});
```

---

## 📊 Database Schema (Firestore)

### Collections:

#### users/
```json
{
  "uid": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+62xxx",
  "createdAt": "timestamp"
}
```

#### locations/
```json
{
  "userId": "user123",
  "lat": -6.2088,
  "lng": 106.8456,
  "timestamp": "timestamp",
  "accuracy": 10.5
}
```

#### panic_alerts/
```json
{
  "userId": "user123",
  "location": {
    "lat": -6.2088,
    "lng": 106.8456
  },
  "timestamp": "timestamp",
  "status": "active"
}
```

---

## 🎯 Design Principles

1. **Mobile-First**
   - App works offline
   - Minimal battery drain
   - Fast UI

2. **Fail-Safe**
   - App works without backend
   - Graceful degradation
   - Error handling

3. **Privacy-First**
   - End-to-end encryption (future)
   - Minimal data collection
   - User control

4. **Scalable**
   - Horizontal scaling (backend)
   - Firebase auto-scales
   - Modular architecture

---

**Next:** [Setup Guide](SETUP.md)
