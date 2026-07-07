<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\Materi;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ReviewController extends Controller
{
    /**
     * 1. GET - Ambil semua review untuk satu buku
     */
    public function getBookReviews($materiId)
    {
        $reviews = Review::where('materi_id', $materiId)
            ->with(['user:id,name,email,profile_image'])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $reviews,
            'total' => $reviews->count()
        ]);
    }

    /**
     * 2. GET - Ambil review yang dibuat user
     */
    public function getUserReviews()
    {
        $userId = Auth::id();
        $reviews = Review::where('user_id', $userId)
            ->with(['materi:id,title,image'])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $reviews
        ]);
    }

    /**
     * 3. POST - Buat/update review untuk buku
     */
    public function createReview(Request $request)
    {
        $request->validate([
            'materi_id' => 'required|exists:materis,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000'
        ]);

        $userId = Auth::id();
        
        // Cek apakah user sudah pernah review buku ini
        $existingReview = Review::where('user_id', $userId)
            ->where('materi_id', $request->materi_id)
            ->first();

        if ($existingReview) {
            // Update review
            $existingReview->update([
                'rating' => $request->rating,
                'comment' => $request->comment
            ]);
            $review = $existingReview;
        } else {
            // Buat review baru
            $review = Review::create([
                'user_id' => $userId,
                'materi_id' => $request->materi_id,
                'rating' => $request->rating,
                'comment' => $request->comment
            ]);
        }

        // Update rata-rata rating di table materis
        $this->updateBookRating($request->materi_id);

        // Kirim notifikasi (opsional)
        // Notification::create([...]);

        return response()->json([
            'success' => true,
            'message' => 'Review berhasil disimpan',
            'data' => $review
        ]);
    }

    /**
     * 4. DELETE - Hapus review
     */
    public function deleteReview($reviewId)
    {
        $review = Review::findOrFail($reviewId);
        
        $userId = Auth::id();
        if ($review->user_id != $userId) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak bisa hapus review orang lain'
            ], 403);
        }

        $materiId = $review->materi_id;
        $review->delete();

        // Update rata-rata rating
        $this->updateBookRating($materiId);

        return response()->json([
            'success' => true,
            'message' => 'Review berhasil dihapus'
        ]);
    }

    /**
     * Helper: Update average rating di table materis
     */
    private function updateBookRating($materiId)
    {
        $reviews = Review::where('materi_id', $materiId)->get();
        $averageRating = $reviews->avg('rating');
        $reviewCount = $reviews->count();

        Materi::find($materiId)->update([
            'average_rating' => round($averageRating, 2),
            'review_count' => $reviewCount
        ]);
    }
}
