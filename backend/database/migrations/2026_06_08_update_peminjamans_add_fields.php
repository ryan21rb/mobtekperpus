<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('peminjamans', function (Blueprint $table) {
            // Tambahan kolom untuk tracking peminjaman
            // Note: due_date, returned_at sudah ada di migration sebelumnya
            $table->integer('days_late')->default(0)->after('returned_at');
            $table->integer('fine_amount')->default(0)->after('days_late');
            $table->boolean('fine_paid')->default(false)->after('fine_amount');
        });
    }

    public function down(): void
    {
        Schema::table('peminjamans', function (Blueprint $table) {
            $table->dropColumn([
                'days_late', 'fine_amount', 'fine_paid'
            ]);
        });
    }
};
