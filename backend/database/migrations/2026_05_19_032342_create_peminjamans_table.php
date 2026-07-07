<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('peminjamans', function (Blueprint $table) {
            $table->id(); // ID Transaksi Peminjaman
            
            // Relasi ke tabel users (siapa yang meminjam)
            // onDelete('cascade') artinya jika user dihapus, data pinjamannya ikut terhapus
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            
            // Relasi ke tabel materis (buku apa yang dipinjam)
            $table->foreignId('materi_id')->constrained('materis')->onDelete('cascade');
            
            // Kolom tanggal pinjam, default-nya adalah tanggal hari ini saat disisipkan
            $table->date('tanggal_pinjam')->default(now());
            
            // Status peminjaman menggunakan enum sesuai kebutuhan Flutter kamu (Dipinjam / Kembali)
            $table->enum('status', ['Dipinjam', 'Kembali'])->default('Dipinjam');
            
            $table->timestamps(); // create_at dan updated_at
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('peminjamans');
    }
};