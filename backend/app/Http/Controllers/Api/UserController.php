<?php

namespace App\Http\Controllers\Api; // Namespace disesuaikan dengan folder Api

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    // GET /api/users -> Ambil semua data user untuk halaman "User & Role" di Flutter
    public function index()
    {
        try {
            $users = User::select('id', 'name', 'email', 'role')->get();
            
            // Langsung kembalikan array JSON agar Flutter tidak membaca sebagai object/map kosong
            return response()->json($users, 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal mengambil data user: ' . $e->getMessage()
            ], 500);
        }
    }

    // PUT /api/users/{id}/role -> Mengubah role user dari modal Flutter
    public function updateRole(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'role' => 'required|in:Admin,Petugas,User' // Sesuaikan huruf kapitalnya dengan isi DB kamu
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'fail',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = User::find($id);

            if (!$user) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'User tidak ditemukan'
                ], 404);
            }

            $user->role = $request->role;
            $user->save();

            return response()->json([
                'status' => 'success',
                'message' => 'Role berhasil diperbarui',
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal memperbarui role: ' . $e->getMessage()
            ], 500);
        }
    }
}