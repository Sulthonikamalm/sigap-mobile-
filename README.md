# SIGAP Mobile App

## 📱 Overview

Aplikasi mobile SIGAP untuk pelaporan pelecehan seksual dengan fitur:
- 🔐 Authentication (Firebase)
- 📍 Location tracking & nearby users
- 🚨 Panic button
- 💬 Chat & support
- 📊 Reporting system

---

## 🏗️ Architecture

**Hybrid System: Flutter + Golang + Firebase**

```
┌─────────────┐
│   Flutter   │ (Frontend - User Interface)
│   Mobile    │
└──────┬──────┘
       │
       ├─────────────┐
       │             │
       ▼             ▼
┌─────────────┐  ┌─────────────┐
│  Firebase   │  │   Golang    │
│  (Primary)  │  │  (Optional) │
│             │  │             │
│ - Auth      │  │ - Heavy     │
│ - Firestore │  │   Logic     │
│ - FCM       │  │ - Analytics │
└─────────────┘  └─────────────┘
```

**Key Points:**
- ✅ App works **without** Golang (Firebase only)
- ✅ Golang adds **advanced features** (optional)
- ✅ Firebase as **primary database**

---

## 📁 Project Structure

```
app/
├── frontend/          # Flutter app
├── backend/           # Golang server (optional)
└── docs/              # Documentation
```


## 🚀 Quick Start

### Frontend (Flutter):
```bash
cd frontend
flutter pub get
flutter run
```

### Backend (Golang):
```bash
cd backend
go mod download
go run cmd/server/main.go
```

---

## 🔗 Repositories

- **Frontend:** [Link to Flutter repo]
- **Backend:** [Link to Golang repo]
- **Main:** This repository (coordination)

---

## 📚 Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Setup Guide](docs/SETUP.md)
- [API Documentation](docs/API.md)

---

## 🛠️ Tech Stack

### Frontend:
- Flutter 3.x
- Firebase (Auth, Firestore, FCM)
- Provider (State management)

### Backend:
- Golang 1.21+
- Fiber (Web framework)
- Firebase Admin SDK

---

## 👥 Team

- Developer: [Your name]
- Advisor: [Advisor name]

---

## 📝 License

MIT License

---

**Status:** 🚧 In Development



C:\Users\Sulth\.gemini\antigravity\brain\161cd4d7-6428-4a20-b32b-3efcc69794d9\catatan_backend_native_pantau_aku.md.resolved