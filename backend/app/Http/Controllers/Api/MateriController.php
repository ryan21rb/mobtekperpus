<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Materi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MateriController extends Controller
{
    /**
     * 1. READ (GET) - Mengambil semua data materi
     */
    public function index()
    {
        $materi = Materi::all();
        return response()->json($materi, 200);
    }

    /**
     * 2. CREATE (POST) - Menyimpan data materi baru beserta file gambar
     */
    public function store(Request $request)
    {
        // Validasi input data dari Flutter (Sudah di-upgrade ke 10MB)
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'stock' => 'nullable|integer|min:0',
            'category' => 'nullable|string|max:255',
            'author' => 'nullable|string|max:255',
            'publication_year' => 'nullable|integer|between:1901,2155',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:10240' 
        ]);

        $imagePath = null;
        // Jika ada file gambar yang diupload
        if ($request->hasFile('image')) {
            // Menyimpan file ke dalam folder storage/app/public/materi
            $imagePath = $request->file('image')->store('materi', 'public');
        }

        $materi = Materi::create([
            'title' => $request->title,
            'description' => $request->description,
            'image' => $imagePath,
            'stock' => $request->stock ?? 1,
            'category' => $request->category,
            'author' => $request->author,
            'publication_year' => $request->publication_year,
        ]);

        return response()->json($materi, 201);
    }

    /**
     * 3. UPDATE (PUT/PATCH) - Memperbarui data materi dan mengganti gambar lama
     */
    public function update(Request $request, $id)
    {
        $materi = Materi::find($id);

        if (!$materi) {
            return response()->json(['message' => 'Data materi tidak ditemukan'], 404);
        }

        // Validasi input pembaruan (Sudah di-upgrade ke 10MB juga agar sinkron saat edit)
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'stock' => 'nullable|integer|min:0',
            'category' => 'nullable|string|max:255',
            'author' => 'nullable|string|max:255',
            'publication_year' => 'nullable|integer|between:1901,2155',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:10240'
        ]);

        // Pertahankan path gambar yang lama secara default
        $imagePath = $materi->image;

        // Jika user memilih/mengupload gambar baru lewat modal Flutter
        if ($request->hasFile('image')) {
            // Hapus gambar lama dari penyimpanan lokal server jika file lamanya ada
            if ($materi->image && Storage::disk('public')->exists($materi->image)) {
                Storage::disk('public')->delete($materi->image);
            }
            // Simpan gambar baru yang masuk
            $imagePath = $request->file('image')->store('materi', 'public');
        }

        // Update data di database
        $materi->update([
            'title' => $request->title,
            'description' => $request->description,
            'image' => $imagePath,
            'stock' => $request->stock ?? $materi->stock,
            'category' => $request->category,
            'author' => $request->author,
            'publication_year' => $request->publication_year,
        ]);


        return response()->json($materi, 200);
    }

    /**
     * 4. DELETE (DELETE) - Menghapus data materi beserta file gambarnya
     */
    public function destroy($id)
    {
        $materi = Materi::find($id);

        if (!$materi) {
            return response()->json(['message' => 'Data materi tidak ditemukan'], 404);
        }

        // Hapus file gambar dari folder penyimpanan sebelum menghapus baris data database
        if ($materi->image && Storage::disk('public')->exists($materi->image)) {
            Storage::disk('public')->delete($materi->image);
        }

        $materi->delete();

        return response()->json(['message' => 'Materi berhasil dihapus'], 200);
    }

    /**
     * 5. SEARCH & FILTER - Pencarian advanced dengan filter kategori, pengarang, tahun
     */
    public function search(Request $request)
    {
        $request->validate([
            'keyword' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'author' => 'nullable|string|max:255',
            'year' => 'nullable|integer',
            'min_rating' => 'nullable|numeric|min:0|max:5',
            'sort_by' => 'nullable|in:title,rating,newest,stock',
            'limit' => 'nullable|integer|min:1|max:100'
        ]);

        $query = Materi::query();

        // Search by keyword (title, description, author)
        if ($request->has('keyword') && $request->keyword) {
            $keyword = $request->keyword;
            $query->where(function ($q) use ($keyword) {
                $q->where('title', 'like', "%$keyword%")
                  ->orWhere('description', 'like', "%$keyword%")
                  ->orWhere('author', 'like', "%$keyword%");
            });
        }

        // Filter by category
        if ($request->has('category') && $request->category) {
            $query->where('category', $request->category);
        }

        // Filter by author
        if ($request->has('author') && $request->author) {
            $query->where('author', 'like', "%{$request->author}%");
        }

        // Filter by year
        if ($request->has('year') && $request->year) {
            $query->where('publication_year', $request->year);
        }

        // Filter by minimum rating
        if ($request->has('min_rating') && $request->min_rating) {
            $query->where('average_rating', '>=', $request->min_rating);
        }

        // Sort by parameter
        if ($request->has('sort_by')) {
            switch ($request->sort_by) {
                case 'rating':
                    $query->orderBy('average_rating', 'desc');
                    break;
                case 'newest':
                    $query->orderBy('created_at', 'desc');
                    break;
                case 'stock':
                    $query->orderBy('stock', 'desc');
                    break;
                default:
                    $query->orderBy('title', 'asc');
            }
        } else {
            $query->orderBy('title', 'asc');
        }

        // Get distinct categories and authors for filtering options
        $allCategories = Materi::distinct()->pluck('category')->filter()->values();
        $allAuthors = Materi::distinct()->pluck('author')->filter()->values();

        // Limit results
        $limit = $request->limit ?? 20;
        $results = $query->paginate($limit);

        return response()->json([
            'success' => true,
            'data' => $results->items(),
            'pagination' => [
                'total' => $results->total(),
                'per_page' => $results->perPage(),
                'current_page' => $results->currentPage(),
                'last_page' => $results->lastPage()
            ],
            'filters' => [
                'categories' => $allCategories,
                'authors' => $allAuthors
            ]
        ]);
    }

    /**
     * 6. GET - Ambil daftar unik kategori
     */
    public function getCategories()
    {
        $categories = Materi::distinct()
            ->pluck('category')
            ->filter()
            ->values();

        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }

    /**
     * 7. GET - Ambil daftar unik author
     */
    public function getAuthors()
    {
        $authors = Materi::distinct()
            ->pluck('author')
            ->filter()
            ->values();

        return response()->json([
            'success' => true,
            'data' => $authors
        ]);
    }

    /**
     * 8. GET - Ambil daftar unik tahun publikasi
     */
    public function getPublicationYears()
    {
        $years = Materi::distinct()
            ->orderBy('publication_year', 'desc')
            ->pluck('publication_year')
            ->filter()
            ->values();

        return response()->json([
            'success' => true,
            'data' => $years
        ]);
    }

    /**
     * 9. GET - Ambil buku populer (trending)
     */
    public function getPopular(Request $request)
    {
        $limit = $request->limit ?? 10;
        
        $popular = Materi::orderBy('average_rating', 'desc')
            ->where('average_rating', '>', 0)
            ->limit($limit)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $popular
        ]);
    }

    /**
     * 10. GET - Ambil buku terbaru
     */
    public function getNewest(Request $request)
    {
        $limit = $request->limit ?? 10;
        
        $newest = Materi::orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $newest
        ]);
    }

    /**
     * 11. GET - Detail single book dengan review
     */
    public function show($id)
    {
        $materi = Materi::find($id);

        if (!$materi) {
            return response()->json(['success' => false, 'message' => 'Buku tidak ditemukan'], 404);
        }

        // Get reviews
        $reviews = \App\Models\Review::where('materi_id', $id)
            ->with(['user:id,name,profile_image'])
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => array_merge($materi->toArray(), [
                'reviews' => $reviews
            ])
        ]);
    }

    /**
     * 12. GET - Serve image file with proper CORS headers
     */
    public function serveImage($filename)
    {
        $path = storage_path('app/public/materi/' . $filename);

        if (!file_exists($path)) {
            return response()->json(['error' => 'Image not found'], 404);
        }

        return response()->file($path, [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => 'Content-Type',
            'Content-Type' => mime_content_type($path),
            'Cache-Control' => 'public, max-age=3600'
        ]);
    }
}