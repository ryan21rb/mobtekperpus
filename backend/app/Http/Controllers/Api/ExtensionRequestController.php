<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\ExtensionRequest;
use App\Models\Peminjaman;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class ExtensionRequestController extends Controller
{
    /**
     * 1. GET - Ambil semua extension request user
     */
    public function getMyRequests()
    {
        $userId = Auth::id();
        $requests = ExtensionRequest::where('user_id', $userId)
            ->with(['peminjaman' => function ($query) {
                $query->with(['materi:id,title,image', 'user:id,name']);
            }])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $requests
        ]);
    }

    /**
     * 2. POST - Buat request perpanjangan
     */
    public function createRequest(Request $request)
    {
        $request->validate([
            'peminjaman_id' => 'required|exists:peminjamans,id',
            'reason' => 'nullable|string|max:500',
            'extension_days' => 'required|integer|min:1|max:14'
        ]);

        $userId = Auth::id();
        $peminjaman = Peminjaman::find($request->peminjaman_id);

        // Validasi: peminjaman harus milik user
        if ($peminjaman->user_id != $userId) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak bisa request perpanjangan buku orang lain'
            ], 403);
        }

        // Validasi: status harus 'dipinjam'
        if (strtolower($peminjaman->status) != 'dipinjam') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya bisa perpanjang buku yang masih dipinjam'
            ]);
        }

        // Validasi: belum ada request pending
        $pendingRequest = ExtensionRequest::where('peminjaman_id', $request->peminjaman_id)
            ->where('status', 'pending')
            ->first();

        if ($pendingRequest) {
            return response()->json([
                'success' => false,
                'message' => 'Sudah ada request perpanjangan yang pending'
            ]);
        }

        // Hitung new due date
        $currentDueDate = Carbon::parse($peminjaman->due_date);
        $newDueDate = $currentDueDate->addDays($request->extension_days);

        $extensionRequest = ExtensionRequest::create([
            'peminjaman_id' => $request->peminjaman_id,
            'user_id' => $userId,
            'status' => 'pending',
            'reason' => $request->reason,
            'extension_days' => $request->extension_days,
            'new_due_date' => $newDueDate
        ]);

        // Kirim notifikasi ke admin
        // TODO: Send notification to admin/petugas

        return response()->json([
            'success' => true,
            'message' => 'Request perpanjangan berhasil dikirim',
            'data' => $extensionRequest
        ]);
    }

    /**
     * 3. ADMIN - GET pending requests
     */
    public function getPendingRequests()
    {
        $requests = ExtensionRequest::where('status', 'pending')
            ->with(['peminjaman' => function ($query) {
                $query->with(['user:id,name,email', 'materi:id,title']);
            }])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $requests
        ]);
    }

    /**
     * 4. ADMIN - Approve request perpanjangan
     */
    public function approveRequest(Request $request, $requestId)
    {
        $extensionRequest = ExtensionRequest::find($requestId);
        
        if (!$extensionRequest) {
            return response()->json([
                'success' => false,
                'message' => 'Request tidak ditemukan'
            ], 404);
        }

        // Update request status
        $extensionRequest->update(['status' => 'approved']);

        // Update due_date di peminjaman
        $peminjaman = $extensionRequest->peminjaman;
        $peminjaman->update(['due_date' => $extensionRequest->new_due_date]);

        // Kirim notifikasi ke user
        Notification::create([
            'user_id' => $extensionRequest->user_id,
            'type' => 'extension',
            'title' => 'Perpanjangan Disetujui',
            'message' => 'Permintaan perpanjangan buku ' . $peminjaman->materi->title . ' telah disetujui. Jatuh tempo baru: ' . $extensionRequest->new_due_date,
            'peminjaman_id' => $peminjaman->id
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Request perpanjangan berhasil disetujui'
        ]);
    }

    /**
     * 5. ADMIN - Reject request perpanjangan
     */
    public function rejectRequest(Request $request, $requestId)
    {
        $extensionRequest = ExtensionRequest::find($requestId);
        
        if (!$extensionRequest) {
            return response()->json([
                'success' => false,
                'message' => 'Request tidak ditemukan'
            ], 404);
        }

        $extensionRequest->update(['status' => 'rejected']);

        // Kirim notifikasi ke user
        Notification::create([
            'user_id' => $extensionRequest->user_id,
            'type' => 'extension',
            'title' => 'Perpanjangan Ditolak',
            'message' => 'Permintaan perpanjangan Anda ditolak',
            'peminjaman_id' => $extensionRequest->peminjaman_id
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Request perpanjangan berhasil ditolak'
        ]);
    }
}
