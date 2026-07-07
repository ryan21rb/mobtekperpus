<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('peminjamans', function (Blueprint $table) {
            $table->date('due_date')->nullable()->after('status');
            $table->integer('denda')->default(0)->after('due_date');
            $table->date('returned_at')->nullable()->after('denda');
            
            $table->index(['status', 'user_id']);
            $table->index('due_date');
        });
    }

    public function down(): void
    {
        Schema::table('peminjamans', function (Blueprint $table) {
            $table->dropColumn(['due_date', 'denda', 'returned_at']);
            $table->dropIndex(['status', 'user_id']);
            $table->dropIndex(['due_date']);
        });
    }
};
