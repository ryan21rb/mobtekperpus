<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Peminjaman extends Model
{
    use HasFactory;

    // Menentukan nama tabel secara eksplisit
    protected $table = 'peminjamans';

    // Kolom yang boleh diisi lewat API
    protected $fillable = [
        'user_id',
        'materi_id',
        'status',
        'due_date',
        'denda',
        'returned_at',
        'days_late',
        'fine_amount',
        'fine_paid',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function materi()
    {
        return $this->belongsTo(Materi::class, 'materi_id');
    }
}