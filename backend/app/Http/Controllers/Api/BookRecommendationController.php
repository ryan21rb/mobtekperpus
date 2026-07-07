<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BookRecommendation;
use App\Models\Peminjaman;
use App\Models\Materi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class BookRecommendationController extends Controller
{
    /**
     * 1. GET - Ambil rekomendasi buku untuk user
     */
    public function getRecommendations()
    {
        $userId = Auth::id();
        
        // Jika belum ada rekomendasi, generate terlebih dahulu
        $hasRecommendations = BookRecommendation::where('user_id', $userId)->exists();
        
        if (!$hasRecommendations) {
            $this->generateRecommendations($userId);
        }

        $recommendations = BookRecommendation::where('user_id', $userId)
            ->with(['materi' => function ($query) {
                $query->select('id', 'title', 'description', 'author', 'category', 'image', 'average_rating', 'stock');
            }])
            ->orderBy('score', 'desc')
            ->limit(10)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $recommendations->map(function ($rec) {
                return array_merge(
                    $rec->materi->toArray(),
                    ['reason' => $rec->reason, 'score' => $rec->score]
                );
            })
        ]);
    }

    /**
     * 2. PRIVATE - Generate rekomendasi berdasarkan riwayat peminjaman
     */
    private function generateRecommendations($userId)
    {
        // Ambil kategori dari buku yang sudah dipinjam user
        $userBorrowedCategories = Peminjaman::where('user_id', $userId)
            ->with('materi:id,category')
            ->get()
            ->pluck('materi.category')
            ->unique()
            ->toArray();

        // Ambil author dari buku yang sudah dipinjam
        $userBorrowedAuthors = Peminjaman::where('user_id', $userId)
            ->with('materi:id,author')
            ->get()
            ->pluck('materi.author')
            ->unique()
            ->toArray();

        // Ambil ID buku yang sudah dipinjam
        $borrowedBookIds = Peminjaman::where('user_id', $userId)
            ->pluck('materi_id')
            ->unique()
            ->toArray();

        // Ambil ID buku yang sudah di-review/favorite
        $reviewedAndFavoritedIds = DB::table('reviews')
            ->where('user_id', $userId)
            ->pluck('materi_id')
            ->merge(
                DB::table('favorites')
                    ->where('user_id', $userId)
                    ->pluck('materi_id')
            )
            ->unique()
            ->toArray();

        // Rekomendasi: buku dengan kategori yang sama
        $sameCategory = Materi::whereIn('category', $userBorrowedCategories)
            ->whereNotIn('id', array_merge($borrowedBookIds, $reviewedAndFavoritedIds))
            ->select('id', 'average_rating')
            ->limit(5)
            ->get();

        foreach ($sameCategory as $book) {
            BookRecommendation::updateOrCreate(
                ['user_id' => $userId, 'materi_id' => $book->id],
                ['score' => $book->average_rating + 5, 'reason' => 'same_category']
            );
        }

        // Rekomendasi: buku dengan author yang sama
        $sameAuthor = Materi::whereIn('author', $userBorrowedAuthors)
            ->whereNotIn('id', array_merge($borrowedBookIds, $reviewedAndFavoritedIds))
            ->select('id', 'average_rating')
            ->limit(5)
            ->get();

        foreach ($sameAuthor as $book) {
            BookRecommendation::updateOrCreate(
                ['user_id' => $userId, 'materi_id' => $book->id],
                ['score' => $book->average_rating + 3, 'reason' => 'same_author']
            );
        }

        // Rekomendasi: buku dengan rating tinggi
        $highRated = Materi::whereNotIn('id', array_merge($borrowedBookIds, $reviewedAndFavoritedIds))
            ->where('average_rating', '>=', 4)
            ->orderBy('average_rating', 'desc')
            ->select('id', 'average_rating')
            ->limit(5)
            ->get();

        foreach ($highRated as $book) {
            BookRecommendation::updateOrCreate(
                ['user_id' => $userId, 'materi_id' => $book->id],
                ['score' => $book->average_rating + 2, 'reason' => 'high_rating']
            );
        }

        // Rekomendasi: buku trending (banyak dipinjam)
        $trending = DB::table('peminjamans')
            ->select('materi_id', DB::raw('count(*) as borrow_count'))
            ->groupBy('materi_id')
            ->whereNotIn('materi_id', array_merge($borrowedBookIds, $reviewedAndFavoritedIds))
            ->orderBy('borrow_count', 'desc')
            ->limit(5)
            ->pluck('materi_id')
            ->toArray();

        foreach ($trending as $materiId) {
            $book = Materi::find($materiId);
            BookRecommendation::updateOrCreate(
                ['user_id' => $userId, 'materi_id' => $book->id],
                ['score' => $book->average_rating + 1, 'reason' => 'trending']
            );
        }
    }

    /**
     * 3. POST - Refresh rekomendasi
     */
    public function refreshRecommendations()
    {
        $userId = Auth::id();
        
        // Hapus rekomendasi lama
        BookRecommendation::where('user_id', $userId)->delete();

        // Generate ulang
        $this->generateRecommendations($userId);

        return response()->json([
            'success' => true,
            'message' => 'Rekomendasi berhasil di-refresh'
        ]);
    }
}
