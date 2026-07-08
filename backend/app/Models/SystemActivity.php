<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SystemActivity extends Model
{
    use HasFactory;

    protected $table = 'system_activities';

    protected $fillable = [
        'user_id',
        'user_name',
        'user_role',
        'activity_type',
        'details',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
