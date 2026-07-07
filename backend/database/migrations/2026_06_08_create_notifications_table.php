<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            
            // Tipe notifikasi: borrow, return, extension, overdue, review
            $table->enum('type', ['borrow', 'return', 'extension', 'overdue', 'review'])->default('borrow');
            
            $table->string('title');
            $table->text('message');
            
            // Relasi optional ke peminjaman
            $table->foreignId('peminjaman_id')->nullable()->constrained('peminjamans')->onDelete('cascade');
            
            // Relasi optional ke buku
            $table->foreignId('materi_id')->nullable()->constrained('materis')->onDelete('cascade');
            
            // Status baca
            $table->boolean('is_read')->default(false);
            
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
