<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Peminjaman;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class UserProfileController extends Controller
{
    /**
     * 1. GET - Ambil profil user lengkap
     */
    public function getProfile()
    {
        $userId = Auth::id();
        $user = User::find($userId);

        // Hitung statistik peminjaman
        $stats = $this->calculateStats($userId);

        return response()->json([
            'success' => true,
            'data' => array_merge($user->toArray(), $stats)
        ]);
    }

    /**
     * 2. PUT - Update profil user
     */
    public function updateProfile(Request $request)
    {
        $userId = Auth::id();
        $user = User::find($userId);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|string|email|max:255|unique:users,email,' . $userId,
            'phone' => 'sometimes|string|max:20',
            'address' => 'sometimes|string|max:500',
            'birth_date' => 'sometimes|date',
            'department' => 'sometimes|string|max:255',
            'profile_image' => 'sometimes|image|mimes:jpeg,png,jpg|max:5120'
        ]);

        $data = $request->only(['name', 'email', 'phone', 'address', 'birth_date', 'department']);

        // Handle image upload
        if ($request->hasFile('profile_image')) {
            $imagePath = $request->file('profile_image')->store('profile', 'public');
            $data['profile_image'] = $imagePath;
        }

        $emailChanged = false;
        if (isset($data['email']) && $data['email'] !== $user->email) {
            $emailChanged = true;
        }

        $user->update($data);

        $newToken = null;
        if ($emailChanged) {
            // Revoke current active tokens to invalidate old session
            $user->tokens()->delete();
            // Generate a fresh personal access token
            $newToken = $user->createToken('auth_token')->plainTextToken;
        }

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui',
            'data' => $user,
            'token' => $newToken
        ]);
    }

    /**
     * 3. GET - Ambil statistik peminjaman user
     */
    public function getStats()
    {
        $userId = Auth::id();
        $stats = $this->calculateStats($userId);

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }

    /**
     * 4. GET - Ambil riwayat peminjaman dengan detail
     */
    public function getBorrowingHistory()
    {
        $userId = Auth::id();
        $peminjamans = Peminjaman::where('user_id', $userId)
            ->with(['materi' => function ($query) {
                $query->select('id', 'title', 'author', 'category', 'image');
            }])
            ->orderBy('tanggal_pinjam', 'desc')
            ->get();

        $formatted = $peminjamans->map(function ($item) {
            $itemArray = $item->toArray();
            $itemArray['title'] = $item->materi->title ?? 'Buku Tidak Diketahui';
            $itemArray['materi_title'] = $item->materi->title ?? 'Buku Tidak Diketahui';
            $itemArray['tanggal_peminjaman'] = $item->tanggal_pinjam;
            $itemArray['image'] = $item->materi->image ?? null;
            return $itemArray;
        });

        return response()->json([
            'success' => true,
            'data' => $formatted
        ]);
    }

    /**
     * 5. GET - Ambil buku yang sedang dipinjam
     */
    public function getCurrentBorrowings()
    {
        $userId = Auth::id();
        $currentBorrowings = Peminjaman::where('user_id', $userId)
            ->whereIn('status', ['dipinjam', 'pending_kembali'])
            ->with(['materi' => function ($query) {
                $query->select('id', 'title', 'author', 'image');
            }])
            ->get();

        // Tambah info denda dan status keterlambatan
        $formatted = $currentBorrowings->map(function ($item) {
            $daysLate = 0;
            $estimatedFine = 0;

            if ($item->due_date) {
                $now = Carbon::now()->startOfDay();
                $dueDate = Carbon::parse($item->due_date)->startOfDay();
                
                if ($now->greaterThan($dueDate)) {
                    $daysLate = $now->diffInDays($dueDate);
                    $estimatedFine = $daysLate * 10000; // Rp 10000 per hari
                }
            }

            $itemArray = $item->toArray();
            $itemArray['title'] = $item->materi->title ?? 'Buku Tidak Diketahui';
            $itemArray['materi_title'] = $item->materi->title ?? 'Buku Tidak Diketahui';
            $itemArray['tanggal_peminjaman'] = $item->tanggal_pinjam;
            $itemArray['image'] = $item->materi->image ?? null;
            $itemArray['days_late'] = $daysLate;
            $itemArray['estimated_fine'] = $estimatedFine;
            $itemArray['is_overdue'] = $daysLate > 0;

            return $itemArray;
        });

        return response()->json([
            'success' => true,
            'data' => $formatted
        ]);
    }

    /**
     * 6. PUT - Update password
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed'
        ]);

        $userId = Auth::id();
        $user = User::find($userId);

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password lama tidak sesuai'
            ], 401);
        }

        $user->update(['password' => Hash::make($request->new_password)]);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah'
        ]);
    }

    /**
     * PRIVATE - Helper function untuk hitung statistik
     */
    private function calculateStats($userId)
    {
        $totalBorrowed = Peminjaman::where('user_id', $userId)->count();
        $totalReturned = Peminjaman::where('user_id', $userId)->whereIn('status', ['kembali', 'dikembalikan'])->count();
        
        $totalOverdue = Peminjaman::where('user_id', $userId)
            ->where('status', 'dipinjam')
            ->whereDate('due_date', '<', Carbon::now()->startOfDay())
            ->count();

        $totalFine = Peminjaman::where('user_id', $userId)
            ->sum('denda');

        $activeBorrowings = Peminjaman::where('user_id', $userId)
            ->whereIn('status', ['dipinjam', 'pending_kembali'])
            ->count();

        return [
            'total_borrowed' => $totalBorrowed,
            'total_borrowings' => $totalBorrowed,
            'total_returned' => $totalReturned,
            'total_overdue' => $totalOverdue,
            'active_borrowings' => $activeBorrowings,
            'total_fine' => $totalFine,
            'total_fines' => $totalFine,
            'fine_paid' => $totalFine, // Assume semua sudah dibayar
            'member_since' => $this->getMemberSince($userId)
        ];
    }

    /**
     * PRIVATE - Helper function untuk hitung member since
     */
    private function getMemberSince($userId)
    {
        $user = User::find($userId);
        return $user->created_at;
    }
}
