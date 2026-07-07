<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run()
    {
        DB::table('users')->insert([
            // 1. Admin
            [
                'name' => 'Admin Utama',
                'email' => 'admin@gmail.com',
                'password' => Hash::make('password123'),
                'role' => 'admin',
                'created_at' => now(),
            ],
            // 2. Petugas
            [
                'name' => 'Petugas Jaga',
                'email' => 'petugas@gmail.com',
                'password' => Hash::make('password123'),
                'role' => 'petugas',
                'created_at' => now(),
            ],
            // 3. User Biasa
            [
                'name' => 'User Biasa',
                'email' => 'user@gmail.com',
                'password' => Hash::make('password123'),
                'role' => 'user',
                'created_at' => now(),
            ],
        ]);
    }
}