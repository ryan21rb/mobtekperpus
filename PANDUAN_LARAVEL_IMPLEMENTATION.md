# 🔧 IMPLEMENTASI LARAVEL - IWU Library Backend Controllers

---

## 1. Migration Files

### File: `database/migrations/2026_06_08_add_peminjaman_columns.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('peminjamans', function (Blueprint $table) {
            // Tambah kolom baru setelah status
            $table->date('due_date')->nullable()->after('status');
            $table->integer('denda')->default(0)->after('due_date');
            $table->date('returned_at')->nullable()->after('denda');
            
            // Index untuk query performa cepat
            $table->index(['status', 'user_id']);
            $table->index('due_date');
        });
    }

    public function down(): void
    {
        Schema::table('peminjamans', function (Blueprint $table) {
            $table->dropColumn(['due_date', 'denda', 'returned_at']);
            $table->dropIndex(['status', 'user_id']);
            $table->dropIndex(['due_date']);
        });
    }
};
```

### File: `database/migrations/2026_06_08_add_materis_columns.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('materis', function (Blueprint $table) {
            // DIHAPUS: Tidak ada kolom baru untuk materis
        });
    }

    public function down(): void
    {
        Schema::table('materis', function (Blueprint $table) {
            // Tidak ada kolom yang dihapus
        });
    }
};
```

**Cara Run Migration:**
```bash
php artisan migrate
```

---

## 2. Model Updates

### File: `app/Models/Peminjaman.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Peminjaman extends Model
{
    protected $table = 'peminjamans';
    protected $fillable = [
        'user_id',
        'materi_id',
        'status',
        'due_date',
        'denda',
        'returned_at',
    ];

    protected $casts = [
        'due_date' => 'date',
        'returned_at' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ============ RELATIONSHIPS ============
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function materi()
    {
        return $this->belongsTo(Materi::class);
    }

    // ============ HELPER METHODS ============

    /**
     * Hitung denda otomatis berdasarkan due_date
     * Denda: Rp 2.000 per hari keterlambatan
     */
    public function calculateFine()
    {
        if (!in_array($this->status, ['dikembalikan', 'pending_kembali'])) {
            return 0;
        }

        $dueDate = Carbon::parse($this->due_date);
        $today = Carbon::now();

        if ($today > $dueDate) {
            $daysLate = $today->diffInDays($dueDate);
            return $daysLate * 2000; // Rp 2.000 per hari
        }

        return 0;
    }

    /**
     * Hitung hari keterlambatan
     */
    public function getDaysLate()
    {
        $dueDate = Carbon::parse($this->due_date);
        $today = Carbon::now();

        if ($today > $dueDate) {
            return $today->diffInDays($dueDate);
        }

        return 0;
    }

    // ============ SCOPES ============

    /**
     * Scope: Get pending returns
     */
    public function scopePendingReturn($query)
    {
        return $query->where('status', 'pending_kembali');
    }

    /**
     * Scope: Get active borrows for specific user
     */
    public function scopeBorrowedByUser($query, $userId)
    {
        return $query->where('user_id', $userId)
                     ->where('status', 'dipinjam');
    }

    /**
     * Scope: Get overdue items
     */
    public function scopeOverdue($query)
    {
        return $query->where('status', 'dipinjam')
                     ->whereDate('due_date', '<', Carbon::now()->format('Y-m-d'));
    }
}
```

### File: `app/Models/Materi.php` (Update)

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Materi extends Model
{
    protected $table = 'materis';
    protected $fillable = [
        'title',
        'description',
    ];

    // ============ RELATIONSHIPS ============

    public function peminjamans()
    {
        return $this->hasMany(Peminjaman::class);
    }
}
```

---

## 3. Controller Implementation

### File: `app/Http/Controllers/PeminjamanController.php`

```php
<?php

namespace App\Http\Controllers;

use App\Models\Peminjaman;
use App\Models\Materi;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class PeminjamanController extends Controller
{
    // ==================== GET ENDPOINTS ====================

    /**
     * GET /api/peminjaman
     * Ambil semua data peminjaman (untuk Admin/Petugas)
     * 
     * @response {
     *   "success": true,
     *   "message": "Data peminjaman berhasil diambil",
     *   "data": [...]
     * }
     */
    public function index()
    {
        try {
            $peminjamans = Peminjaman::with(['user', 'materi'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Data peminjaman berhasil diambil',
                'data' => $peminjamans,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data peminjaman',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/peminjaman/pending-return
     * Ambil data peminjaman yang pending dikembalikan (untuk Petugas)
     * Termasuk kalkulasi days_late dan estimated_fine
     */
    public function getPendingReturns()
    {
        try {
            $pendingReturns = Peminjaman::with(['user', 'materi'])
                ->pendingReturn()
                ->orderBy('due_date', 'asc')
                ->get()
                ->map(function ($item) {
                    // Tambahkan kalkulasi denda di response
                    $item->days_late = $item->getDaysLate();
                    $item->estimated_fine = $item->calculateFine();
                    return $item;
                });

            return response()->json([
                'success' => true,
                'message' => 'Data pengembalian pending berhasil diambil',
                'count' => count($pendingReturns),
                'data' => $pendingReturns,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data pengembalian pending',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/peminjaman/user/{userId}
     * Ambil data peminjaman user tertentu
     * 
     * @param int $userId User ID
     * @response {
     *   "success": true,
     *   "message": "Data peminjaman user berhasil diambil",
     *   "data": [...]
     * }
     */
    public function getUserPeminjaman($userId)
    {
        try {
            $user = User::find($userId);
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User tidak ditemukan',
                ], 404);
            }

            $peminjamans = Peminjaman::with('materi')
                ->where('user_id', $userId)
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Data peminjaman user berhasil diambil',
                'data' => $peminjamans,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data peminjaman user',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // ==================== POST ENDPOINTS ====================

    /**
     * POST /api/peminjaman/request-return
     * Mahasiswa request pengembalian buku (ubah status ke pending_kembali)
     * 
     * @bodyParam peminjaman_id int required ID peminjaman
     */
    public function requestReturn(Request $request)
    {
        try {
            $validated = $request->validate([
                'peminjaman_id' => 'required|integer|exists:peminjamans,id',
            ]);

            $peminjaman = Peminjaman::find($validated['peminjaman_id']);

            // Validasi: hanya bisa request return jika status = dipinjam
            if ($peminjaman->status !== 'dipinjam') {
                return response()->json([
                    'success' => false,
                    'message' => 'Buku sudah tidak berstatus dipinjam',
                    'code' => 'INVALID_STATUS',
                ], 400);
            }

            $peminjaman->status = 'pending_kembali';
            $peminjaman->save();

            return response()->json([
                'success' => true,
                'message' => 'Permintaan pengembalian berhasil dikirim ke petugas',
                'data' => [
                    'peminjaman_id' => $peminjaman->id,
                    'status' => $peminjaman->status,
                    'book_title' => $peminjaman->materi->title,
                ],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat request pengembalian',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/peminjaman/{id}/verify-return
     * Petugas/Admin verifikasi pengembalian & hitung denda otomatis
     * 
     * PROSES:
     * 1. Validasi status peminjaman = pending_kembali
     * 2. Hitung hari keterlambatan (today - due_date)
     * 3. Hitung denda: hari_terlambat × 2000
     * 4. Update status menjadi 'dikembalikan'
     * 5. Return response dengan detail denda
     * 
     * @param int $id Peminjaman ID
     * @response {
     *   "success": true,
     *   "message": "Pengembalian buku berhasil diverifikasi",
     *   "data": {
     *     "peminjaman_id": 5,
     *     "book_title": "Algoritma",
     *     "due_date": "2026-06-07",
     *     "returned_at": "2026-06-08",
     *     "days_late": 1,
     *     "fine_per_day": 2000,
     *     "total_fine": 2000
     *   }
     * }
     */
    public function verifyReturn($id)
    {
        try {
            $peminjaman = Peminjaman::with('materi')->find($id);

            if (!$peminjaman) {
                return response()->json([
                    'success' => false,
                    'message' => 'Peminjaman tidak ditemukan',
                    'code' => 'PEMINJAMAN_NOT_FOUND',
                ], 404);
            }

            // Validasi status
            if ($peminjaman->status !== 'pending_kembali') {
                return response()->json([
                    'success' => false,
                    'message' => 'Hanya peminjaman dengan status pending_kembali yang bisa diverifikasi',
                    'code' => 'INVALID_STATUS',
                ], 400);
            }

            // === HITUNG DENDA ===
            $dueDate = Carbon::parse($peminjaman->due_date);
            $today = Carbon::now();
            
            // Hitung hari terlambat
            $daysLate = $today->greaterThan($dueDate) 
                ? $today->diffInDays($dueDate) 
                : 0;

            // Hitung total denda (Rp 2.000 per hari)
            $fine = $daysLate > 0 ? $daysLate * 2000 : 0;

            // === UPDATE RECORD ===
            $peminjaman->status = 'dikembalikan';
            $peminjaman->returned_at = $today->format('Y-m-d');
            $peminjaman->denda = $fine;
            $peminjaman->save();

            return response()->json([
                'success' => true,
                'message' => 'Pengembalian buku berhasil diverifikasi',
                'data' => [
                    'peminjaman_id' => $peminjaman->id,
                    'book_title' => $peminjaman->materi->title,
                    'user_id' => $peminjaman->user_id,
                    'status' => $peminjaman->status,
                    'due_date' => $peminjaman->due_date->format('Y-m-d'),
                    'returned_at' => $peminjaman->returned_at,
                    'days_late' => $daysLate,
                    'fine_per_day' => 2000,
                    'total_fine' => $fine,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memverifikasi pengembalian',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/peminjaman
     * Create peminjaman manual (untuk admin)
     * 
     * @bodyParam user_id int required ID pengguna
     * @bodyParam materi_id int required ID buku
     * @bodyParam days_duration int optional Durasi peminjaman (default: 7)
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'user_id' => 'required|integer|exists:users,id',
                'materi_id' => 'required|integer|exists:materis,id',
                'days_duration' => 'nullable|integer|min:1|max:30',
            ]);

            $user = User::find($validated['user_id']);
            $materi = Materi::find($validated['materi_id']);

            // Cek limit peminjaman
            $activeBorrows = Peminjaman::where('user_id', $validated['user_id'])
                ->where('status', 'dipinjam')
                ->count();

            if ($activeBorrows >= 5) {
                return response()->json([
                    'success' => false,
                    'message' => 'User sudah mencapai limit peminjaman (5 buku)',
                ], 400);
            }

            $daysDuration = $validated['days_duration'] ?? 7;
            $dueDate = Carbon::now()->addDays($daysDuration);

            $peminjaman = Peminjaman::create([
                'user_id' => $validated['user_id'],
                'materi_id' => $validated['materi_id'],
                'status' => 'dipinjam',
                'due_date' => $dueDate,
                'denda' => 0,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Peminjaman berhasil dibuat',
                'data' => $peminjaman,
            ], 201);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat peminjaman',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

}
```

---

## 4. Routes Configuration

### File: `routes/api.php` (Update)

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PeminjamanController;

// ===== AUTH ROUTES (Sudah ada) =====
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// ===== PROTECTED ROUTES =====
Route::middleware('auth:sanctum')->group(function () {
    
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'getCurrentUser']);
    
    // ===== PEMINJAMAN ROUTES =====
    
    // GET Endpoints
    Route::get('/peminjaman', [PeminjamanController::class, 'index']);
    Route::get('/peminjaman/pending-return', [PeminjamanController::class, 'getPendingReturns']);
    Route::get('/peminjaman/user/{userId}', [PeminjamanController::class, 'getUserPeminjaman']);
    
    // POST Endpoints
    Route::post('/peminjaman', [PeminjamanController::class, 'store']);
    Route::post('/peminjaman/request-return', [PeminjamanController::class, 'requestReturn']);
    Route::post('/peminjaman/{id}/verify-return', [PeminjamanController::class, 'verifyReturn']);
});
```

---

## 5. CORS Configuration

### File: `config/cors.php` (Pastikan sudah benar)

```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
        'http://localhost:3000',      // Frontend dev
        'http://localhost:8080',      // Alternative dev
        'http://localhost:5173',      // Vite default
        'http://localhost:64335',     // Flutter web dev (adjust port sesuai)
        'http://127.0.0.1:64335',
    ],
    'allowed_origins_patterns' => ['localhost*'],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
```

**⚠️ CATATAN PENTING:**
- Update `allowed_origins` sesuai port Flutter web Anda
- Untuk production, ganti dengan domain asli

---

## 6. Testing dengan Curl

```bash
# 1. Login dulu
curl -X POST "http://localhost:8000/api/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@gmail.com",
    "password": "password"
  }'

# Response akan berisi token. Copy token untuk digunakan di request berikutnya

TOKEN="your_token_here"

# 2. Get pending returns
curl -X GET "http://localhost:8000/api/peminjaman/pending-return" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json"

# 3. Request Return
curl -X POST "http://localhost:8000/api/peminjaman/request-return" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "peminjaman_id": 5
  }'

# 4. Verify Return & Hitung Denda
curl -X POST "http://localhost:8000/api/peminjaman/5/verify-return" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

---

## 📋 Database Table Schema Reference

```sql
-- Table: users (existing)
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    role ENUM('admin', 'petugas', 'user') DEFAULT 'user',
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Table: materis (existing)
CREATE TABLE materis (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Table: peminjamans (update dengan kolom baru)
CREATE TABLE peminjamans (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT REFERENCES users(id),
    materi_id BIGINT REFERENCES materis(id),
    status ENUM('dipinjam', 'pending_kembali', 'dikembalikan') DEFAULT 'dipinjam',
    due_date DATE NULLABLE,                    -- NEW
    denda INT DEFAULT 0,                       -- NEW (denda dalam Rupiah)
    returned_at DATE NULLABLE,                 -- NEW
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX (status, user_id),
    INDEX (due_date)
);
```

---

## 🔍 Checklist Implementasi Backend

- [ ] Run migrations: `php artisan migrate`
- [ ] Update Model Peminjaman dengan helper methods
- [ ] Buat PeminjamanController dengan semua endpoints
- [ ] Update routes/api.php dengan routes baru
- [ ] Test semua endpoints dengan Curl
- [ ] Validate CORS configuration
- [ ] Test authorization (pastikan auth:sanctum bekerja)
