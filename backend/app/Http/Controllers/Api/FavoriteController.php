<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use App\Models\Materi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class FavoriteController extends Controller
{
    /**
     * 1. GET - Ambil semua favorit user dengan detail buku
     */
    public function getUserFavorites()
    {
        $userId = Auth::id();
        $favorites = Favorite::where('user_id', $userId)
            ->with(['materi' => function ($query) {
                $query->select('id', 'title', 'description', 'author', 'category', 'image', 'average_rating', 'stock');
            }])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $favorites->pluck('materi'),
            'total' => $favorites->count()
        ]);
    }

    /**
     * 2. GET - Cek apakah buku sudah difavoritkan
     */
    public function isFavorite($materiId)
    {
        $userId = Auth::id();
        $isFavorite = Favorite::where('user_id', $userId)
            ->where('materi_id', $materiId)
            ->exists();

        return response()->json([
            'success' => true,
            'is_favorite' => $isFavorite
        ]);
    }

    /**
     * 3. POST - Tambah ke favorit
     */
    public function addFavorite(Request $request)
    {
        $request->validate([
            'materi_id' => 'required|exists:materis,id'
        ]);

        $userId = Auth::id();
        
        // Cek sudah di-favorite atau belum
        $existing = Favorite::where('user_id', $userId)
            ->where('materi_id', $request->materi_id)
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Buku sudah ada di favorit'
            ]);
        }

        $favorite = Favorite::create([
            'user_id' => $userId,
            'materi_id' => $request->materi_id
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Buku berhasil ditambahkan ke favorit',
            'data' => $favorite
        ]);
    }

    /**
     * 4. DELETE - Hapus dari favorit
     */
    public function removeFavorite($materiId)
    {
        $userId = Auth::id();
        $favorite = Favorite::where('user_id', $userId)
            ->where('materi_id', $materiId)
            ->first();

        if (!$favorite) {
            return response()->json([
                'success' => false,
                'message' => 'Buku tidak ada di favorit'
            ]);
        }

        $favorite->delete();

        return response()->json([
            'success' => true,
            'message' => 'Buku berhasil dihapus dari favorit'
        ]);
    }
}
