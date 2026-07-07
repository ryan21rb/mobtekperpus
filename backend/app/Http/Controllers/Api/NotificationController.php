<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    /**
     * 1. GET - Ambil semua notifikasi user
     */
    public function getNotifications()
    {
        $userId = Auth::id();
        $notifications = Notification::where('user_id', $userId)
            ->with(['materi:id,title,image', 'peminjaman:id,materi_id,due_date'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $notifications
        ]);
    }

    /**
     * 2. GET - Ambil notifikasi yang belum dibaca
     */
    public function getUnreadNotifications()
    {
        $userId = Auth::id();
        $unreadCount = Notification::where('user_id', $userId)
            ->where('is_read', false)
            ->count();

        $notifications = Notification::where('user_id', $userId)
            ->where('is_read', false)
            ->with(['materi:id,title,image', 'peminjaman:id,materi_id,due_date'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'unread_count' => $unreadCount,
            'data' => $notifications
        ]);
    }

    /**
     * 3. PUT - Mark notifikasi sebagai sudah dibaca
     */
    public function markAsRead($notificationId)
    {
        $notification = Notification::find($notificationId);
        
        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notifikasi tidak ditemukan'
            ], 404);
        }

        $notification->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi ditandai sudah dibaca'
        ]);
    }

    /**
     * 4. PUT - Mark semua notifikasi sebagai sudah dibaca
     */
    public function markAllAsRead()
    {
        $userId = Auth::id();
        Notification::where('user_id', $userId)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Semua notifikasi ditandai sudah dibaca'
        ]);
    }

    /**
     * 5. DELETE - Hapus notifikasi
     */
    public function deleteNotification($notificationId)
    {
        $notification = Notification::find($notificationId);
        
        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notifikasi tidak ditemukan'
            ], 404);
        }

        $notification->delete();

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi berhasil dihapus'
        ]);
    }

    /**
     * 6. DELETE - Hapus semua notifikasi
     */
    public function deleteAllNotifications()
    {
        $userId = Auth::id();
        Notification::where('user_id', $userId)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Semua notifikasi berhasil dihapus'
        ]);
    }
}
