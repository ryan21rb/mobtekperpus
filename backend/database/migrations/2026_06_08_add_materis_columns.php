<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('materis', function (Blueprint $table) {
            $table->string('barcode')->nullable()->unique()->after('title');
            $table->string('qr_code')->nullable()->after('barcode');
            $table->integer('stock')->default(1)->after('qr_code');
            
            $table->index('barcode');
        });
    }

    public function down(): void
    {
        Schema::table('materis', function (Blueprint $table) {
            $table->dropColumn(['barcode', 'qr_code', 'stock']);
            $table->dropIndex(['barcode']);
        });
    }
};
