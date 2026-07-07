<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('book_recommendations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('materi_id')->constrained('materis')->onDelete('cascade');
            
            // Score/relevance untuk ranking rekomendasi
            $table->decimal('score', 5, 2)->default(0);
            
            // Alasan rekomendasi
            $table->enum('reason', ['same_category', 'same_author', 'popular', 'high_rating', 'trending'])->default('popular');
            
            $table->timestamps();
            
            // Unique: satu user hanya punya 1 rekomendasi per buku
            $table->unique(['user_id', 'materi_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('book_recommendations');
    }
};
