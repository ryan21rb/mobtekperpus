<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SystemActivity;
use Illuminate\Http\Request;

class SystemActivityController extends Controller
{
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user || (strtolower($user->role) !== 'admin')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only Admin can access system activities.'
                ], 403);
            }

            $activities = SystemActivity::orderBy('created_at', 'desc')->get();

            return response()->json([
                'success' => true,
                'data' => $activities
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }
}
