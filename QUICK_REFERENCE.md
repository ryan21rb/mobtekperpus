# 📖 QUICK REFERENCE - Setup & Testing Guide

## ⚡ Setup Cepat

### 1. Backend Laravel Setup

```bash
# Di folder backend/
cd backend

# A. Run migrations
php artisan migrate

# B. Seed data test (optional - buat sendiri atau manual)

# C. Test server
php artisan serve --host=0.0.0.0 --port=8000
```

### 2. Frontend Flutter Setup

```bash
# Di folder frontend/
cd frontend

# Copy file-file baru ke folder yang sesuai:
# - frontend/lib/services/api_service.dart (update dengan method baru)
# - frontend/lib/screens/user_peminjaman_screen.dart (NEW)
# - frontend/lib/screens/petugas_return_queue_screen.dart (NEW)

# Run Flutter
flutter run -d chrome
# atau
flutter run -d windows
```

### 3. Update main.dart Routes

```dart
// lib/main.dart - Tambahkan routes baru

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IWU Library',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/materi': (context) => const MateriScreen(),        // Admin
        '/petugas': (context) => const PetugasScreen(),      // Petugas
        '/user': (context) => const UserScreen(),            // User
        
        // ===== ROUTES BARU =====
        '/peminjaman': (context) => const UserPeminjamanScreen(),
        '/petugas/return': (context) => const PetugasReturnQueueScreen(),
      },
    );
  }
}
```

---

## 🧪 Testing Scenario

### Scenario 1: User Request Return Buku

**Prerequisites:**
- User sudah login
- User sudah punya peminjaman dengan status 'dipinjam'

**Steps:**
1. User masuk ke `/peminjaman` screen
2. Lihat list buku yang dipinjam
3. Klik tombol "Kembalikan Buku"
4. Confirm dialog
5. Status berubah ke 'pending_kembali'
6. Tunggu petugas verifikasi

**Expected Result:**
- ✅ Dialog konfirmasi muncul
- ✅ Permintaan terkirim ke backend
- ✅ Status berubah di database
- ✅ UI update otomatis

---

### Scenario 2: Petugas Verify Return & Hitung Denda

**Prerequisites:**
- Ada peminjaman dengan status 'pending_kembali'
- Peminjaman sudah melewati due_date (untuk test denda)

**Steps:**
1. Petugas masuk ke `/petugas/return` screen
2. Lihat antrean pengembalian
3. Klik card peminjaman yang akan diverifikasi
4. Dialog muncul dengan detail:
   - Nama peminjam
   - Judul buku
   - Hari terlambat (jika ada)
   - Total denda (jika ada)
5. Klik "Setujui Pengembalian"
6. Loading... processing
7. Success snackbar dengan info denda

**Expected Result:**
- ✅ List menampilkan hanya pending_kembali
- ✅ Dialog detail akurat
- ✅ Denda dihitung otomatis (hari_terlambat × 2000)
- ✅ Status berubah ke 'dikembalikan'
- ✅ Item hilang dari queue
- ✅ Stock buku bertambah 1

**Test Denda:**
- Due date buku: 2026-06-07
- Verifikasi return pada: 2026-06-08
- Expected denda: 1 hari × 2000 = Rp 2.000 ✓

---

## 🐛 Debugging Tips

### Issue: CORS Error

**Error:** `Access to XMLHttpRequest at 'http://localhost:8000/...' from origin 'http://localhost:64335' has been blocked by CORS policy`

**Solution:**
```php
// config/cors.php
'allowed_origins' => [
    'http://localhost:64335',  // Update port sesuai Flutter dev server Anda
],
```

Cek port Flutter:
```
flutter run -d chrome
// Lihat di console: "To hot reload changes while running, press 'r'..."
// Port biasanya di atas
```

---

### Issue: 401 Unauthorized

**Error:** `{"success": false, "message": "Unauthorized"}`

**Cause:** Token tidak dikirim atau expired

**Solution:**
```dart
// Pastikan token disimpan di authService
final user = await _authService.getCurrentUser();
if (user == null) {
  // Redirect ke login
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}
```

---

### Issue: Denda Tidak Hitung

**Symptom:** Verify return tapi denda tetap 0

**Debug:**
```php
// Di backend - enable query logging
\Illuminate\Support\Facades\DB::listen(function ($query) {
    logger()->info($query->sql, $query->bindings);
});

// Di Controller - tambah debug log
\Log::info('Due Date: ' . $peminjaman->due_date);
\Log::info('Today: ' . Carbon::now());
\Log::info('Days Late: ' . $daysLate);
\Log::info('Fine: ' . $fine);
```

**Common Issues:**
- Due date format tidak benar (pastikan Y-m-d)
- Timezone tidak sama
- Date comparison error

---

## 📊 Database Query Examples

```sql
-- Lihat semua peminjaman pending return
SELECT p.*, m.title, u.name 
FROM peminjamans p
JOIN materis m ON p.materi_id = m.id
JOIN users u ON p.user_id = u.id
WHERE p.status = 'pending_kembali'
ORDER BY p.due_date ASC;

-- Lihat peminjaman yang sudah terlambat
SELECT p.*, m.title, u.name,
       DATEDIFF(CURDATE(), p.due_date) as days_late
FROM peminjamans p
JOIN materis m ON p.materi_id = m.id
JOIN users u ON p.user_id = u.id
WHERE p.status = 'dipinjam'
  AND p.due_date < CURDATE();

-- Lihat total denda per user
SELECT u.name, u.id,
       SUM(p.denda) as total_denda,
       COUNT(p.id) as total_peminjaman_dikembalikan
FROM users u
JOIN peminjamans p ON u.id = p.user_id
WHERE p.status = 'dikembalikan'
GROUP BY u.id
ORDER BY total_denda DESC;

-- Lihat stock buku
SELECT id, title, stock
FROM materis
ORDER BY stock DESC;
```

---

## 🚀 Production Checklist

- [ ] Validasi semua error handling
- [ ] Test dengan network latency tinggi
- [ ] Test dengan large dataset (1000+ records)
- [ ] Update CORS dengan domain production
- [ ] Set timezone yang sama di backend & frontend
- [ ] Implement logging untuk debug production issues
- [ ] Backup database sebelum production
- [ ] Update API rate limiting
- [ ] Add authentication middleware properly
- [ ] Test dengan berbagai browser/devices
- [ ] Implement refresh token logic
- [ ] Add offline capability (optional)
- [ ] Optimize API responses (pagination)

---

## 📞 Troubleshooting Contact Points

| Issue | Check | Solution |
|-------|-------|----------|
| Token expired | AuthService | Implement refresh token |
| No data showing | API response | Check API endpoints return correct data |
| Denda tidak hitung | Due date format | Validate date format Y-m-d |
| Denda tidak hitung | Due date format | Validate date format Y-m-d |
| Stock tidak berkurang | API logic | Check decrement() method di controller |
| UI tidak update | setState() | Ensure setState called after API call |

---

## 📝 Notes untuk Dokumentasi Internal

**Fitur yang diimplementasikan:**
1. ✅ Verifikasi pengembalian buku otomatis
2. ✅ Kalkulasi denda otomatis (Rp 2.000/hari)
3. ✅ Queue antrean pengembalian untuk petugas
4. ✅ Tracking due date dan returned date

**Database Changes:**
- Peminjamans: +3 columns (due_date, denda, returned_at)

**New Endpoints:**
- POST /api/peminjaman/request-return
- POST /api/peminjaman/{id}/verify-return
- GET /api/peminjaman/pending-return
- GET /api/peminjaman/user/{userId}

**New Screens:**
- UserPeminjamanScreen (view borrowings + request return)
- PetugasReturnQueueScreen (verify return + calculate fine)

**Integrasi dengan existing:**
- Menggunakan existing auth & navigation
- Compatible dengan existing sidebar
- Consistent dengan existing UI design
