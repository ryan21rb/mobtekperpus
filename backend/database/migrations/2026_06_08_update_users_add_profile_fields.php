<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Tambahan kolom untuk profil user
            $table->string('phone')->nullable()->after('email');
            $table->string('address')->nullable()->after('phone');
            $table->string('profile_image')->nullable()->after('address');
            $table->date('birth_date')->nullable()->after('profile_image');
            $table->string('department')->nullable()->after('birth_date');
            $table->integer('total_borrowed')->default(0)->after('department');
            $table->integer('total_returned')->default(0)->after('total_borrowed');
            $table->integer('total_overdue')->default(0)->after('total_returned');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'phone', 'address', 'profile_image', 'birth_date', 'department',
                'total_borrowed', 'total_returned', 'total_overdue'
            ]);
        });
    }
};
