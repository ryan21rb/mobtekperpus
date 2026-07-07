<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MateriSeeder extends Seeder
{
    public function run()
    {
        DB::table('materis')->insert([
            [
                'title' => 'Pengenalan Flutter', 
                'description' => 'Belajar dasar-dasar UI Flutter dengan Widget.',
                'image' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Database SQLite', 
                'description' => 'Cara menyimpan data secara lokal di HP.',
                'image' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'title' => 'Integrasi API', 
                'description' => 'Menghubungkan aplikasi Flutter ke Laravel.',
                'image' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}