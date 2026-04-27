# Architecture Overview — SIGAP Mobile App

> **Referensi Utama:** Dokumen ini adalah turunan teknis dari [TECHSTACK_GRAND_DESIGN.md](../../TECHSTACK_GRAND_DESIGN.md).
> Semua keputusan arsitektural di bawah ini sudah melalui proses evaluasi komparatif 3 skenario (Full Firebase, Hybrid Firebase, dan SQL-Centric Microservice) yang didokumentasikan pada Bab 4 Grand Design.

---

## 🏗️ System Design

### Arsitektur Terpilih: Polyglot Microservice SQL-Centric

```
┌─────────────────────────────────────────────────────────┐
│               Flutter Mobile App (Dart)                 │
│    App Mahasiswa (Pelaporan) & App Satgas Lite (Admin)   │
└───────────────────────┬─────────────────────────────────┘
                        │ HTTP/REST
                        ▼
          ┌──────────────────────────┐
          │    Golang REST API       │
          │   (Mobile Backend)       │
          │  • Validasi & Logika     │
          │  • Concurrency tinggi    │
          │  • FCM Trigger           │
          └─────┬──────────┬─────────┘
                │          │
                ▼          ▼
  ┌──────────────────┐  ┌─────────────────────┐
  │  MySQL Database  │  │  Firebase FCM        │
  │  (Shared SSOT)   │  │  (Push Notification  │
  │  • Data kasus    │  │   ONLY — Gratis)     │
  │  • Users & roles │  └─────────┬───────────┘
  │  • Log & audit   │            │
  └────────┬─────────┘            ▼
           │              ┌───────────────┐
           │              │ 📱 HP Satgas  │
           ▼              │ (Alarm Sirine)│
  ┌──────────────────┐    └───────────────┘
  │  PHP Web Server  │
  │  (Admin Dashboard)│
  │  • SSR HTML/CSS   │
  │  • PDF/Excel Gen  │
  │  • Statistik Berat│
  └──────────────────┘
```

### Mengapa Arsitektur Ini Dipilih? (Ringkasan)

Arsitektur ini dipilih setelah mengevaluasi 3 skenario:
- **Skenario A (Full Firebase):** Ditolak karena biaya *read/write* membengkak, vendor lock-in total, dan mustahil dimodifikasi untuk Blockchain.
- **Skenario B (Go+PHP+Firestore):** Ditolak karena PHP sangat lambat (2-5x) saat dipaksa mengolah data dari NoSQL, biaya tetap tinggi.
- **Skenario C (Go+PHP+MySQL+FCM) ✅:** Terpilih karena biaya operasional rendah, data di server kampus, query SQL native untuk dashboard, dan kesiapan evolusi ke Blockchain.

Penjelasan lengkap beserta tabel komparasi ada di [TECHSTACK_GRAND_DESIGN.md Bab 4](../../TECHSTACK_GRAND_DESIGN.md).

---

## 🗄️ Database Utama: MySQL (Single Source of Truth)

### Mengapa MySQL dan Bukan Firebase Firestore?

| Aspek | MySQL (Terpilih ✅) | Firebase Firestore (Ditolak ❌) |
|-------|---------------------|-------------------------------|
| **Biaya** | Gratis (server lokal) atau VPS murah | Berbayar per *read/write* — membengkak |
| **Query Kompleks** | `JOIN`, `GROUP BY`, Sub-query, Window Functions | Tidak support `JOIN`, filter sangat terbatas |
| **Privasi Data** | Data di server kampus, kontrol penuh | Data di Cloud Google, di luar kendali |
| **PDF/Excel Export** | PHP langsung query SQL → cetak | Harus tarik semua dokumen → rekonstruksi manual |
| **Blockchain Ready** | Bisa disisipkan hash kriptografi di layer SQL | Mustahil, sistem tertutup |

### Skema Database (Tabel Relasional)

#### Tabel `users`
```sql
CREATE TABLE users (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    uid         VARCHAR(128) UNIQUE NOT NULL,  -- Firebase Auth UID (untuk FCM linking)
    nama        VARCHAR(255) NOT NULL,
    email       VARCHAR(255) UNIQUE NOT NULL,
    no_hp       VARCHAR(20),
    role        ENUM('mahasiswa', 'satgas_admin', 'satgas_psikolog', 'rektor') NOT NULL,
    fakultas    VARCHAR(100),
    fcm_token   TEXT,                          -- Token push notification
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### Tabel `kasus_laporan`
```sql
CREATE TABLE kasus_laporan (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    pelapor_id      INT NOT NULL,
    jenis_kasus     ENUM('darurat', 'formal', 'anonim') NOT NULL,
    tingkat_urgensi ENUM('rendah', 'sedang', 'tinggi', 'kritis') NOT NULL,
    kronologi       TEXT NOT NULL,
    lokasi_kejadian VARCHAR(255),
    latitude        DECIMAL(10, 8),
    longitude       DECIMAL(11, 8),
    status          ENUM('baru', 'diproses', 'ditangani', 'selesai', 'ditolak') DEFAULT 'baru',
    ditangani_oleh  INT,                       -- FK ke users (satgas)
    psikolog_id     INT,                       -- FK ke users (psikolog)
    catatan_satgas  TEXT,
    catatan_psikolog TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (pelapor_id) REFERENCES users(id),
    FOREIGN KEY (ditangani_oleh) REFERENCES users(id),
    FOREIGN KEY (psikolog_id) REFERENCES users(id)
);
```

#### Tabel `chat_messages`
```sql
CREATE TABLE chat_messages (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    kasus_id    INT NOT NULL,
    sender_id   INT NOT NULL,
    pesan       TEXT NOT NULL,
    tipe_pesan  ENUM('text', 'image', 'file') DEFAULT 'text',
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kasus_id) REFERENCES kasus_laporan(id),
    FOREIGN KEY (sender_id) REFERENCES users(id)
);
```

#### Tabel `audit_log`
```sql
CREATE TABLE audit_log (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    user_id     INT NOT NULL,
    action      VARCHAR(100) NOT NULL,         -- 'login', 'view_case', 'update_status', dll
    target_type VARCHAR(50),                   -- 'kasus', 'user', 'chat'
    target_id   INT,
    ip_address  VARCHAR(45),
    user_agent  TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Contoh Query Kompleks yang Mustahil di Firebase

```sql
-- Rekapitulasi kasus per fakultas per bulan, dengan info penanganan
SELECT
    u.fakultas,
    MONTH(k.created_at) AS bulan,
    COUNT(*) AS total_kasus,
    SUM(CASE WHEN k.tingkat_urgensi = 'kritis' THEN 1 ELSE 0 END) AS kasus_kritis,
    SUM(CASE WHEN k.status = 'selesai' THEN 1 ELSE 0 END) AS sudah_selesai,
    AVG(TIMESTAMPDIFF(HOUR, k.created_at, k.updated_at)) AS rata_rata_jam_penanganan
FROM kasus_laporan k
JOIN users u ON k.pelapor_id = u.id
WHERE k.created_at >= '2026-01-01'
GROUP BY u.fakultas, MONTH(k.created_at)
ORDER BY u.fakultas, bulan;
```

> Query di atas menghasilkan tabel statistik lengkap dalam **<100ms** di MySQL.
> Di Firestore, untuk mendapatkan hasil yang sama, PHP harus menarik **seluruh** dokumen kasus + dokumen users, merelasikannya secara manual, lalu menghitung agregasi di RAM — bisa memakan waktu **5-30 detik** dan jutaan *reads* berbayar.

---

## ⚙️ Golang Backend (Wajib — Bukan Opsional)

### Peran Utama
Golang bukan lagi "enhancement opsional" seperti di arsitektur lama. Golang adalah **mesin utama** yang menghubungkan seluruh aplikasi mobile ke database:

1. **Mobile REST API Gateway**
   - Menerima seluruh HTTP request dari Flutter (lapor darurat, tarik daftar kasus, kirim chat).
   - Memvalidasi token autentikasi.
   - Menulis/membaca data ke MySQL.

2. **FCM Trigger Engine**
   - Saat ada laporan darurat masuk, Golang secara paralel:
     - Menyimpan data ke MySQL (`INSERT INTO kasus_laporan ...`).
     - Menembak Push Notification via Firebase Admin SDK ke HP Satgas terdekat.

3. **Business Logic Layer**
   - Algoritma penentuan Satgas penanganan berdasarkan kedekatan lokasi.
   - Kalkulasi skor urgensitas kasus.
   - Rate limiting untuk mencegah spam laporan.

### Framework & Struktur
- **Framework:** Fiber (Express-like, sangat cepat) atau net/http standar
- **Database Driver:** `go-sql-driver/mysql`
- **Firebase SDK:** `firebase.google.com/go/v4` (hanya untuk FCM)

```
sigap-golang-api/
├── cmd/
│   └── server/
│       └── main.go              # Entry point
├── internal/
│   ├── handler/                 # HTTP route handlers
│   │   ├── case_handler.go      # CRUD kasus
│   │   ├── auth_handler.go      # Login/register
│   │   └── chat_handler.go      # Pesan chat
│   ├── service/                 # Business logic
│   │   ├── case_service.go
│   │   ├── notification_service.go  # FCM trigger
│   │   └── auth_service.go
│   ├── repository/              # Database access (MySQL)
│   │   ├── case_repo.go
│   │   ├── user_repo.go
│   │   └── chat_repo.go
│   └── middleware/
│       ├── auth_middleware.go    # Token verification
│       └── rate_limiter.go
├── config/
│   ├── database.go              # MySQL connection pool
│   └── firebase.go              # FCM client init
└── go.mod
```

---

## 🔥 Firebase — Hanya untuk Push Notification (FCM)

### Batasan Penggunaan Firebase di SIGAP

| Layanan Firebase | Status | Keterangan |
|------------------|--------|------------|
| **Cloud Messaging (FCM)** | ✅ **DIGUNAKAN** | Satu-satunya layanan Firebase yang aktif. Gratis, tanpa batas kuota. |
| Firestore | ❌ TIDAK digunakan | Database utama adalah MySQL |
| Realtime Database | ❌ TIDAK digunakan | Data real-time dihandle via polling/WebSocket Golang |
| Firebase Auth | ⚠️ Opsional | Bisa dipakai untuk autentikasi awal, tapi token diverifikasi oleh Golang |
| Firebase Hosting | ❌ TIDAK digunakan | Web Admin di-host oleh Apache/Nginx + PHP |
| Firebase Storage | ❌ TIDAK digunakan | File upload disimpan di server lokal |

### Alur FCM Push Notification
```
1. Flutter kirim laporan darurat → Golang API
2. Golang simpan ke MySQL
3. Golang query fcm_token Satgas dari MySQL
4. Golang menembak FCM: "Bunyikan HP Satgas!"
5. FCM mengirim push notification ke HP Satgas
6. HP Satgas bergetar + popup: "DARURAT BARU!"
7. Satgas klik notif → masuk ke admin_lite_page.dart
```

---

## 📱 Flutter Architecture (Mobile App)

### State Management: Provider (ChangeNotifier)

```
lib/
├── core/
│   ├── constants/         # Warna, URL API, konfigurasi
│   ├── services/          # HTTP client, local storage
│   └── utils/             # Helper functions
├── features/
│   ├── auth/              # Login, Register
│   ├── lapor/             # Fitur pelaporan (darurat, formal)
│   ├── chat/              # Percakapan dengan Satgas/Psikolog
│   ├── pantau/            # Live tracking & pantau laporan
│   ├── satgas_lite/       # Dashboard admin & psikolog
│   ├── report_monitor/    # Monitor status laporan
│   ├── notification/      # Notifikasi & FCM
│   ├── home/              # Halaman utama
│   ├── wawasan/           # Artikel edukasi
│   ├── account/           # Profil pengguna
│   ├── onboarding/        # First-time user flow
│   └── app_shell/         # Bottom nav, routing
└── main.dart
```

### Koneksi ke Backend Golang (Bukan ke Firebase)
```dart
// ✅ BENAR — Semua request ke Golang REST API
final response = await http.post(
  Uri.parse('$golangBaseUrl/api/v1/cases/emergency'),
  headers: {'Authorization': 'Bearer $token'},
  body: json.encode(emergencyData),
);

// ❌ SALAH — JANGAN langsung ke Firebase untuk data utama
// FirebaseFirestore.instance.collection('cases').add(data);
// ^ Ini TIDAK digunakan di arsitektur SIGAP
```

---

## 🖥️ PHP Web Dashboard

### Peran
PHP **hanya** melayani Web Admin Dashboard untuk Kepala Satgas / Rektor. PHP **tidak** melayani request dari aplikasi mobile.

### Koneksi ke Database
```php
// PHP langsung query MySQL (bukan Firebase)
$pdo = new PDO("mysql:host=localhost;dbname=sigap_db", $user, $pass);

$stmt = $pdo->prepare("
    SELECT fakultas, COUNT(*) as total
    FROM kasus_laporan k
    JOIN users u ON k.pelapor_id = u.id
    WHERE k.created_at >= :start_date
    GROUP BY fakultas
    ORDER BY total DESC
");
$stmt->execute([':start_date' => '2026-01-01']);
```

---

## 🔐 Security

### Autentikasi Multi-Layer
1. **Flutter → Golang:** JWT Token di header setiap request
2. **Golang:** Verifikasi token, cek role user di MySQL
3. **PHP Dashboard:** Session-based auth dengan password hash (bcrypt)
4. **MySQL:** Prepared statements (anti SQL Injection)

### Audit Trail
Setiap aksi penting (login, lihat kasus, ubah status, kirim pesan) dicatat ke tabel `audit_log` secara otomatis oleh middleware Golang dan PHP.

---

## 🚀 Deployment Strategy

### Phase 1: MVP Fungsional
- Deploy Flutter APK ke device testing
- Golang API di VPS / server kampus
- MySQL di server yang sama
- PHP Dashboard di Apache/XAMPP
- Firebase project aktif (hanya FCM)

### Phase 2: Production
- Golang di-deploy ke VPS dengan reverse proxy (Nginx)
- MySQL dengan backup otomatis harian
- PHP Dashboard di subdomain terpisah
- SSL/HTTPS untuk semua endpoint

### Phase 3: Evolusi Keamanan
- Integrasi hash kriptografi di layer Golang-MySQL
- Proof-of-Validation middleware
- Immutable audit trail

---

## 🎯 Design Principles

1. **SQL-First:** Semua data utama di MySQL relasional. Tidak ada data kritis di NoSQL/Firebase.
2. **Separation of Concerns:** Mobile API (Golang) dan Web Dashboard (PHP) bekerja secara terisolasi di atas database yang sama.
3. **Firebase Minimalis:** Firebase hanya boleh digunakan untuk FCM Push Notification. Tidak untuk database, tidak untuk hosting.
4. **Blockchain-Ready:** Arsitektur Golang+MySQL dirancang agar mudah disisipkan lapisan keamanan kriptografi di masa depan.
5. **Privacy-First:** Data sensitif tidak pernah meninggalkan server kampus. Tidak ada dependency ke cloud storage pihak ketiga untuk data inti.

---

**Referensi:** [Grand Design](../../TECHSTACK_GRAND_DESIGN.md) | [Setup Guide](SETUP.md)
