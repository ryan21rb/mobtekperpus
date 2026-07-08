<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        // Validasi input wajib ada
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        // Cari user berdasarkan email
        $user = User::where('email', $request->email)->first();

        // Cek apakah user ada DAN password cocok
        if ($user && Hash::check($request->password, $user->password)) {
            // Generate Sanctum token untuk authentication
            $token = $user->createToken('auth_token')->plainTextToken;
            
            // Log Aktivitas Login
            \App\Models\SystemActivity::create([
                'user_id' => $user->id,
                'user_name' => $user->name,
                'user_role' => $user->role,
                'activity_type' => 'LOGIN',
                'details' => "Pengguna {$user->name} ({$user->email}) berhasil masuk sebagai " . strtoupper($user->role) . "."
            ]);
            
            return response()->json([
                'message' => 'Login Berhasil',
                'user' => $user,
                'token' => $token
            ], 200);
        }

        // Kalau gagal, kirim respons error
        return response()->json([
            'message' => 'Email/Password salah!'
        ], 401);
    }

    public function register(Request $request)
    {
        try {
            $request->validate([
                'name' => 'required',
                'email' => 'required|email|unique:users',
                'password' => 'required|min:6|confirmed',
            ]);

            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => $request->role ?? 'user', // Default jadi user biasa
            ]);

            // Generate Sanctum token untuk authentication
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'message' => 'Registrasi Berhasil',
                'user' => $user,
                'token' => $token
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validasi Gagal',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }

    public function logout(Request $request)
    {
        try {
            $user = $request->user();
            if ($user) {
                // Log Aktivitas Logout
                \App\Models\SystemActivity::create([
                    'user_id' => $user->id,
                    'user_name' => $user->name,
                    'user_role' => $user->role,
                    'activity_type' => 'LOGOUT',
                    'details' => "Pengguna {$user->name} ({$user->email}) keluar dari sistem."
                ]);

                // Revoke Sanctum token
                $user->currentAccessToken()->delete();
            }
            
            return response()->json([
                'message' => 'Logout Berhasil'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }
}