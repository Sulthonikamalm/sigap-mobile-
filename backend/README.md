# SIGAP Mobile - Golang Backend

## 🚀 Setup

### Prerequisites:
- Go 1.21+
- Firebase Admin SDK credentials

### Installation:
```bash
go mod download
go run cmd/server/main.go
```

---

## 📁 Structure

```
backend/
├── cmd/
│   └── server/
│       └── main.go        # Entry point
├── internal/
│   ├── firebase/          # Firebase Admin SDK
│   └── handlers/          # HTTP handlers
├── config/
│   └── config.go          # Configuration
├── go.mod
└── .env.example
```

---

## 🔥 Firebase Setup

1. Download Firebase Admin SDK JSON
2. Place in `config/firebase-admin-sdk.json`
3. Set environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="config/firebase-admin-sdk.json"
```

---

## 🌐 API Endpoints

### Health Check:
```
GET /health
```

### Nearby Users (example):
```
GET /api/nearby?lat=xxx&lng=xxx&radius=5000
```

---

## 🐳 Docker (Optional)

```bash
docker build -t sigap-backend .
docker run -p 8080:8080 sigap-backend
```

---

**Status:** 🚧 Setup Phase
