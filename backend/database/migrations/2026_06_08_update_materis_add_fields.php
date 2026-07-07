<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('materis', function (Blueprint $table) {
            // Tambahan kolom untuk filter & search
            // Note: barcode, qr_code, stock sudah ada di migration sebelumnya
            $table->string('author')->nullable()->after('description');
            $table->string('category')->nullable()->after('author');
            $table->year('publication_year')->nullable()->after('category');
            $table->decimal('average_rating', 3, 2)->default(0)->after('publication_year');
            $table->integer('review_count')->default(0)->after('average_rating');
        });
    }

    public function down(): void
    {
        Schema::table('materis', function (Blueprint $table) {
            $table->dropColumn([
                'author', 'category', 'publication_year', 'average_rating', 'review_count'
            ]);
        });
    }
};
