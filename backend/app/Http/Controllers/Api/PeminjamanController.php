<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Models\User;
use App\Models\Peminjaman;
use App\Models\Materi;
use Carbon\Carbon;

class PeminjamanController extends Controller
{
    // GET /api/peminjaman -> Ambil semua data peminjaman
    public function index()
    {
        try {
            $peminjaman = DB::table('peminjamans')
                ->leftJoin('users', 'peminjamans.user_id', '=', 'users.id')
                ->leftJoin('materis', 'peminjamans.materi_id', '=', 'materis.id')
                ->select(
                    'peminjamans.id',
                    DB::raw('COALESCE(materis.title, "Buku Tidak Diketahui") as book_title'),
                    'peminjamans.materi_id', 
                    DB::raw('COALESCE(users.name, "Pengguna Tidak Diketahui") as user_name'),
                    'peminjamans.user_id',
                    'peminjamans.status',
                    'peminjamans.due_date',
                    'peminjamans.denda',
                    'peminjamans.returned_at',
                    'peminjamans.created_at',
                    'peminjamans.created_at as date' 
                )
                ->orderBy('peminjamans.id', 'desc')
                ->get();

            return response()->json($peminjaman, 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data peminjaman: ' . $e->getMessage()
            ], 500);
        }
    }

    // GET /api/peminjaman/pending-return -> Ambil data pending return untuk petugas
    public function getPendingReturns()
    {
        try {
            $pendingReturns = DB::table('peminjamans')
                ->join('users', 'peminjamans.user_id', '=', 'users.id')
                ->leftJoin('materis', 'peminjamans.materi_id', '=', 'materis.id')
                ->whereRaw('LOWER(peminjamans.status) = ?', ['pending_kembali'])
                ->select(
                    'peminjamans.id',
                    'peminjamans.user_id',
                    'peminjamans.materi_id', 
                    DB::raw('COALESCE(materis.title, "Buku Tidak Diketahui") as title'),
                    'users.name',
                    'users.email',
                    'peminjamans.due_date',
                    'peminjamans.status',
                    DB::raw('DATEDIFF(CURDATE(), peminjamans.due_date) as days_late'),
                    DB::raw('CASE WHEN DATEDIFF(CURDATE(), peminjamans.due_date) > 0 THEN DATEDIFF(CURDATE(), peminjamans.due_date) * 10000 ELSE 0 END as estimated_fine')
                )
                ->orderBy('peminjamans.due_date', 'asc')
                ->get();

            return response()->json([
                'success' => true,
                'count' => count($pendingReturns),
                'data' => $pendingReturns
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data pending return',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // GET /api/peminjaman/user/{userId} -> Ambil peminjaman milik user tertentu
    public function getUserPeminjaman($userId)
    {
        try {
            $peminjamans = DB::table('peminjamans')
                ->join('materis', 'peminjamans.materi_id', '=', 'materis.id')
                ->where('peminjamans.user_id', $userId)
                ->select(
                    'peminjamans.id',
                    'peminjamans.materi_id',
                    'materis.title',
                    'materis.description',
                    'peminjamans.status',
                    'peminjamans.due_date',
                    'peminjamans.denda',
                    'peminjamans.returned_at',
                    'peminjamans.created_at'
                )
                ->orderBy('peminjamans.created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $peminjamans
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil peminjaman user: ' . $e->getMessage()
            ], 500);
        }
    }

    // POST /api/peminjaman/request-return -> User request return buku
    public function requestReturn(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'peminjaman_id' => 'required|integer|exists:peminjamans,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $peminjaman = DB::table('peminjamans')
                ->where('id', $request->peminjaman_id)
                ->first();

            if (!$peminjaman) {
                return response()->json([
                    'success' => false,
                    'message' => 'Peminjaman tidak ditemukan'
                ], 404);
            }

            if ($peminjaman->status !== 'dipinjam') {
                return response()->json([
                    'success' => false,
                    'message' => 'Hanya buku yang berstatus dipinjam yang bisa dikembalikan'
                ], 400);
            }

            DB::table('peminjamans')
                ->where('id', $request->peminjaman_id)
                ->update([
                    'status' => 'pending_kembali',
                    'updated_at' => now()
                ]);

            return response()->json([
                'success' => true,
                'message' => 'Permintaan pengembalian berhasil dikirim ke petugas',
                'data' => [
                    'peminjaman_id' => $request->peminjaman_id,
                    'status' => 'pending_kembali'
                ]
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat request pengembalian',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // POST /api/peminjaman/{id}/verify-return -> Petugas verify dan hitung denda
    public function verifyReturn($id)
    {
        try {
            $resultData = DB::transaction(function () use ($id) {
                $peminjaman = DB::table('peminjamans')
                    ->join('materis', 'peminjamans.materi_id', '=', 'materis.id')
                    ->where('peminjamans.id', $id)
                    ->lockForUpdate() 
                    ->select('peminjamans.*', 'materis.title')
                    ->first();

                if (!$peminjaman) {
                    return ['status' => 404, 'data' => ['success' => false, 'message' => 'Peminjaman tidak ditemukan']];
                }

                if ($peminjaman->status !== 'pending_kembali') {
                    return ['status' => 400, 'data' => ['success' => false, 'message' => 'Hanya status pending_kembali yang bisa diverifikasi']];
                }

                // Ambil tanggal dengan aman menggunakan Carbon langsung di dalam proses hitung
                $dueDate = Carbon::parse($peminjaman->due_date)->startOfDay();
                $today = Carbon::now()->startOfDay();
                
                // Menggunakan asDateTime atau pembanding bawaan Carbon yang lebih aman (.lt / .gt)
                $daysLate = $today->greaterThan($dueDate) ? $today->diffInDays($dueDate) : 0;
                $fine = $daysLate > 0 ? $daysLate * 10000 : 0;

                DB::table('peminjamans')
                    ->where('id', $id)
                    ->update([
                        'status' => 'kembali',
                        'returned_at' => now()->format('Y-m-d'),
                        'denda' => $fine,
                        'updated_at' => now()
                    ]);

                DB::table('materis')
                    ->where('id', $peminjaman->materi_id)
                    ->increment('stock');

                return [
                    'status' => 200,
                    'data' => [
                        'success' => true,
                        'message' => 'Pengembalian buku berhasil diverifikasi',
                        'data' => [
                            'peminjaman_id' => $id,
                            'book_title' => $peminjaman->title,
                            'status' => 'kembali',
                            'due_date' => $peminjaman->due_date,
                            'returned_at' => now()->format('Y-m-d'),
                            'days_late' => $daysLate,
                            'fine_per_day' => 10000,
                            'total_fine' => $fine
                        ]
                    ]
                ];
            });

            return response()->json($resultData['data'], $resultData['status']);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memverifikasi pengembalian',
                'error' => $e->getMessage()
            ], 500);
        }
    }

// POST /api/peminjaman -> User pinjam buku sendiri (Auth Required)
   public function store(Request $request)
    {
        // Temukan ID Buku, baik dikirim via key 'materi_id' atau 'book_id'
        $materiId = $request->input('materi_id') ?? $request->input('book_id') ?? null;

        // Satukan ke dalam request array agar bisa divalidasi
        $requestData = array_merge($request->all(), ['materi_id' => $materiId]);

        $validator = Validator::make($requestData, [
            'materi_id' => 'required|integer|exists:materis,id',
            'days_duration' => 'nullable|integer|min:1|max:30',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // 2. Ambil ID user langsung dari token yang sedang login
            $userAuth = auth()->user();
            if (!$userAuth) {
                return response()->json([
                    'success' => false,
                    'message' => 'Kalian harus login terlebih dahulu!'
                ], 401);
            }
            
            $userId = $userAuth->id;
            // Ambil input dengan key materi_id atau book_id (untuk compatibility)
            $materiId = intval($request->input('materi_id') ?? $request->input('book_id'));
            
            $daysDuration = $request->days_duration ?? 7;
            $dueDate = Carbon::now()->addDays($daysDuration)->format('Y-m-d');

            $resultData = DB::transaction(function () use ($userId, $materiId, $dueDate) {
                // 3. Cek apakah user sudah minjam buku ini dan statusnya belum kelar
                $isAlreadyBorrowed = DB::table('peminjamans')
                    ->where('user_id', $userId)
                    ->where('materi_id', $materiId)
                    ->whereIn('status', ['dipinjam', 'pending_kembali'])
                    ->exists();

                if ($isAlreadyBorrowed) {
                    return [
                        'status' => 400, 
                        'data' => ['success' => false, 'message' => 'Kamu masih meminjam materi ini dan belum dikonfirmasi selesai!']
                    ];
                }

                // 4. Lock data materi untuk cek stok
                $materi = DB::table('materis')
                    ->where('id', $materiId)
                    ->lockForUpdate()
                    ->first();

                if (!$materi || $materi->stock <= 0) {
                    return [
                        'status' => 400, 
                        'data' => ['success' => false, 'message' => 'Gagal meminjam, stok materi/buku sudah habis!']
                    ];
                }

                // 5. Kurangi stok materi
                DB::table('materis')
                    ->where('id', $materiId)
                    ->update(['stock' => $materi->stock - 1]);

                // 6. Catat data peminjaman ke database
                $peminjamanId = DB::table('peminjamans')->insertGetId([
                    'user_id' => $userId,
                    'materi_id' => $materiId, 
                    'status' => 'dipinjam',
                    'due_date' => $dueDate,
                    'denda' => 0,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);

                return [
                    'status' => 201,
                    'data' => [
                        'success' => true,
                        'message' => 'Peminjaman berhasil dibuat, selamat membaca!',
                        'data' => ['peminjaman_id' => $peminjamanId]
                    ]
                ];
            });

            return response()->json($resultData['data'], $resultData['status']);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat peminjaman',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    // GET /api/peminjaman/materi/{id} -> Fetch material details by ID
    public function getMateriById($id)
    {
        try {
            $materi = DB::table('materis')
                ->where('id', $id)
                ->first();

            if (!$materi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Buku tidak ditemukan',
                    'code' => 'MATERI_NOT_FOUND'
                ], 404);
            }

            $userAuth = auth()->user();
            $alreadyBorrowed = false;
            $activeBorrowCount = 0;

            if ($userAuth) {
                $activeBorrowCount = DB::table('peminjamans')
                    ->where('user_id', $userAuth->id)
                    ->where('status', 'dipinjam')
                    ->count();

                $alreadyBorrowed = DB::table('peminjamans')
                    ->where('user_id', $userAuth->id)
                    ->where('materi_id', $id)
                    ->where('status', 'dipinjam')
                    ->exists();
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $materi->id,
                    'title' => $materi->title,
                    'description' => $materi->description,
                    'image' => $materi->image,
                    'available' => $materi->stock > 0,
                    'already_borrowed' => $alreadyBorrowed,
                    'active_borrow_count' => $activeBorrowCount
                ]
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching material',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // PUT /api/peminjaman/{id}/status -> Update status peminjaman (dipinjam/kembali)
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string'
        ]);

        $status = $request->status;

        try {
            $result = DB::transaction(function () use ($id, $status) {
                $peminjaman = DB::table('peminjamans')
                    ->where('id', $id)
                    ->lockForUpdate()
                    ->first();

                if (!$peminjaman) {
                    return ['status' => 404, 'data' => ['success' => false, 'message' => 'Peminjaman tidak ditemukan']];
                }

                $oldStatus = strtolower($peminjaman->status);
                $newStatus = strtolower($status);

                if ($oldStatus === $newStatus) {
                    return ['status' => 200, 'data' => ['success' => true, 'message' => 'Status sudah sama']];
                }

                $updateData = [
                    'status' => $newStatus,
                    'updated_at' => now()
                ];

                // Jika diubah ke pengembalian (kembali / dikembalikan)
                if (in_array($newStatus, ['kembali', 'dikembalikan'])) {
                    $updateData['returned_at'] = now()->format('Y-m-d');
                    
                    // Increment stok buku
                    DB::table('materis')
                        ->where('id', $peminjaman->materi_id)
                        ->increment('stock');
                }

                // Jika diubah dari pengembalian ke dipinjam lagi
                if ($newStatus === 'dipinjam') {
                    $updateData['returned_at'] = null;

                    // Decrement stok buku
                    DB::table('materis')
                        ->where('id', $peminjaman->materi_id)
                        ->decrement('stock');
                }

                DB::table('peminjamans')
                    ->where('id', $id)
                    ->update($updateData);

                return [
                    'status' => 200,
                    'data' => [
                        'success' => true,
                        'message' => 'Status peminjaman berhasil diperbarui',
                        'data' => [
                            'id' => $id,
                            'status' => $status
                        ]
                    ]
                ];
            });

            return response()->json($result['data'], $result['status']);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memperbarui status peminjaman',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}