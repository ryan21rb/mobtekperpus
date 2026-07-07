<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Materi; // Sesuaikan jika nama modelnya Buku atau Materi
use Illuminate\Support\Facades\DB;

class LaporanController extends Controller
{
   public function getDashboardData()
{
    $totalBuku = DB::table('materis')->count(); 
    $totalAnggota = DB::table('users')->count();
    
    // UBAH DISINI: Sesuaikan dengan string 'dipinjam' dan 'kembali' di phpMyAdmin Anda
    $sedangDipinjam = DB::table('peminjamans')->where('status', 'dipinjam')->count();
    $sudahKembali = DB::table('peminjamans')->where('status', 'kembali')->count();

    $transaksi = DB::table('peminjamans')
        ->join('users', 'peminjamans.user_id', '=', 'users.id')
        ->join('materis', 'peminjamans.materi_id', '=', 'materis.id')
        ->select(
            'peminjamans.id',
            'users.name as user_name',       
            'materis.title as book_title',   
            'peminjamans.tanggal_pinjam as date', // Pastikan kolom ini ada di database Anda
            'peminjamans.status'
        )
        ->orderBy('peminjamans.tanggal_pinjam', 'desc')
        ->take(10) 
        ->get();

    return response()->json([
        'summary' => [
            'total_buku' => $totalBuku,
            'total_user' => $totalAnggota,
            'sedang_dipinjam' => $sedangDipinjam,
            'telah_kembali' => $sudahKembali,
        ],
        'transaksi' => $transaksi
    ], 200);
}
    public function eksporExcel()
{
    // Ambil data transaksi terbaru dari database seperti kemarin
    $transaksi = DB::table('peminjamans')
        ->join('users', 'peminjamans.user_id', '=', 'users.id')
        ->join('materis', 'peminjamans.materi_id', '=', 'materis.id')
        ->select(
            'peminjamans.id',
            'users.name as user_name',
            'materis.title as book_title',
            'peminjamans.tanggal_pinjam as date',
            'peminjamans.status'
        )
        ->orderBy('peminjamans.tanggal_pinjam', 'desc')
        ->get();

    $filename = "laporan_transaksi_" . date('Y-m-d') . ".csv";
    
    $headers = [
        "Content-type"        => "text/csv",
        "Content-Disposition" => "attachment; filename=$filename",
        "Pragma"              => "no-cache",
        "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
        "Expires"             => "0"
    ];

    $columns = ['ID Transaksi', 'Nama Peminjam', 'Judul Buku', 'Tanggal Pinjam', 'Status'];

    $callback = function() use($transaksi, $columns) {
        $file = fopen('php://output', 'w');
        fputcsv($file, $columns);

        foreach ($transaksi as $row) {
            fputcsv($file, [
                $row->id,
                $row->user_name,
                $row->book_title,
                $row->date,
                $row->status
            ]);
        }

        fclose($file);
    };

    return response()->stream($callback, 200, $headers);
}
    public function getSummary()
    {
        try {
            // 1. Hitung total data untuk Dashboard Laporan
            $totalBuku = DB::table('materis')->count();
            $totalUser = DB::table('users')->count();
            $totalPinjam = DB::table('peminjamans')->count();
            $totalDipinjam = DB::table('peminjamans')->where('status', 'dipinjam')->count();
            $totalKembali = DB::table('peminjamans')->where('status', 'kembali')->count();

            // 2. Ambil data aktivitas peminjaman terbaru untuk tabel laporan
            $recentTransactions = DB::table('peminjamans')
                ->join('users', 'peminjamans.user_id', '=', 'users.id')
                ->join('materis', 'peminjamans.materi_id', '=', 'materis.id') // Sesuaikan foreign key Anda
                ->select(
                    'peminjamans.id',
                    'users.name as user_name',
                    'materis.title as book_title',
                    'peminjamans.date',
                    'peminjamans.status'
                )
                ->orderBy('peminjamans.date', 'desc')
                ->take(10) // batasi 10 data terakhir atau hapus ->take() jika ingin semua
                ->get();

            return response()->json([
                'success' => true,
                'summary' => [
                    'total_buku' => $totalBuku,
                    'total_user' => $totalUser,
                    'total_peminjaman' => $totalPinjam,
                    'sedang_dipinjam' => $totalDipinjam,
                    'telah_kembali' => $totalKembali,
                ],
                'latest_transactions' => $recentTransactions
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data laporan: ' . $e->getMessage()
            ], 500);
        }
    }
}