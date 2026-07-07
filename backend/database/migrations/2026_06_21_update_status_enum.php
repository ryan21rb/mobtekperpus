<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Ubah semua status ke lowercase untuk konsistensi
        DB::table('peminjamans')->where('status', 'Dipinjam')->update(['status' => 'dipinjam']);
        DB::table('peminjamans')->where('status', 'Kembali')->update(['status' => 'kembali']);

        // Ubah enum column untuk support semua status values
        Schema::table('peminjamans', function (Blueprint $table) {
            $table->enum('status', ['dipinjam', 'pending_kembali', 'kembali'])->change();
        });
    }

    public function down(): void
    {
        // Revert back to original uppercase values
        DB::table('peminjamans')->where('status', 'dipinjam')->update(['status' => 'Dipinjam']);
        DB::table('peminjamans')->where('status', 'pending_kembali')->update(['status' => 'Dipinjam']);
        DB::table('peminjamans')->where('status', 'kembali')->update(['status' => 'Kembali']);

        Schema::table('peminjamans', function (Blueprint $table) {
            $table->enum('status', ['Dipinjam', 'Kembali'])->change();
        });
    }
};
