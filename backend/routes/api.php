<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MateriController;
use App\Http\Controllers\Api\PeminjamanController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\ExtensionRequestController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\BookRecommendationController;
use App\Http\Controllers\Api\LaporanController;
use App\Http\Controllers\Api\UserProfileController;
use App\Http\Controllers\Api\CategoryController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// ===== AUTH ROUTES =====
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/logout', [AuthController::class, 'logout']); 

// ===== MATERI ROUTES (Publik & Manajemen) =====
Route::get('/materi', [MateriController::class, 'index']);
Route::get('/materi/search', [MateriController::class, 'search']);
Route::get('/materi/popular', [MateriController::class, 'getPopular']);
Route::get('/materi/newest', [MateriController::class, 'getNewest']);
Route::get('/materi/categories', [MateriController::class, 'getCategories']);
Route::get('/materi/authors', [MateriController::class, 'getAuthors']);
Route::get('/materi/years', [MateriController::class, 'getPublicationYears']);
Route::get('/materi/image/{filename}', [MateriController::class, 'serveImage']);
Route::get('/materi/{id}', [MateriController::class, 'show']);
Route::post('/materi', [MateriController::class, 'store']);
Route::put('/materi/{id}', [MateriController::class, 'update']);
Route::delete('/materi/{id}', [MateriController::class, 'destroy']);

// ===== CATEGORY ROUTES =====
Route::get('/categories', [CategoryController::class, 'index']);
Route::post('/categories', [CategoryController::class, 'store']);
Route::put('/categories/{id}', [CategoryController::class, 'update']);
Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

// ===== USER ROUTES =====
Route::get('/users', [UserController::class, 'index']);
Route::put('/users/{id}/role', [UserController::class, 'updateRole']);

// ===== LAPORAN ROUTES =====
Route::get('/laporan/summary', [LaporanController::class, 'getSummary']);
Route::get('/dashboard-laporan', [LaporanController::class, 'getDashboardData']);
Route::get('/ekspor-excel', [LaporanController::class, 'eksporExcel']);

// ===== PEMINJAMAN ROUTES (Publik / Petugas) =====
Route::get('/peminjaman', [PeminjamanController::class, 'index']);
Route::get('/peminjaman/pending-return', [PeminjamanController::class, 'getPendingReturns']);
Route::get('/peminjaman/user/{userId}', [PeminjamanController::class, 'getUserPeminjaman']);
Route::post('/peminjaman/{id}/verify-return', [PeminjamanController::class, 'verifyReturn']);
Route::put('/peminjaman/{id}/status', [PeminjamanController::class, 'updateStatus']);


// =========================================================================
// RUTE YANG WAJIB LOGIN (MIDDLEWARE SANCTUM)
// =========================================================================
Route::middleware('auth:sanctum')->group(function () {

    // Get Data User Login
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // ===== PEMINJAMAN ROUTES (Khusus User Login) =====
    Route::post('/peminjaman', [PeminjamanController::class, 'store']);
    Route::post('/peminjaman/request-return', [PeminjamanController::class, 'requestReturn']);
    Route::get('/peminjaman/materi/{id}', [PeminjamanController::class, 'getMateriById']);

    // ===== USER PROFILE ROUTES =====
    Route::get('/profile', [UserProfileController::class, 'getProfile']);
    Route::put('/profile', [UserProfileController::class, 'updateProfile']);
    Route::get('/profile/stats', [UserProfileController::class, 'getStats']);
    Route::get('/profile/history', [UserProfileController::class, 'getBorrowingHistory']);
    Route::get('/profile/current-borrowings', [UserProfileController::class, 'getCurrentBorrowings']);
    Route::put('/profile/change-password', [UserProfileController::class, 'changePassword']);

    // ===== REVIEW ROUTES =====
    Route::get('/reviews/materi/{materiId}', [ReviewController::class, 'getBookReviews']);
    Route::get('/reviews/my-reviews', [ReviewController::class, 'getUserReviews']);
    Route::post('/reviews', [ReviewController::class, 'createReview']);
    Route::delete('/reviews/{reviewId}', [ReviewController::class, 'deleteReview']);

    // ===== FAVORITE ROUTES =====
    Route::get('/favorites', [FavoriteController::class, 'getUserFavorites']);
    Route::get('/favorites/{materiId}/check', [FavoriteController::class, 'isFavorite']);
    Route::post('/favorites', [FavoriteController::class, 'addFavorite']);
    Route::delete('/favorites/{materiId}', [FavoriteController::class, 'removeFavorite']);

    // ===== EXTENSION REQUEST ROUTES =====
    Route::get('/extension-requests/my-requests', [ExtensionRequestController::class, 'getMyRequests']);
    Route::post('/extension-requests', [ExtensionRequestController::class, 'createRequest']);
    Route::get('/extension-requests/pending', [ExtensionRequestController::class, 'getPendingRequests']);
    Route::put('/extension-requests/{requestId}/approve', [ExtensionRequestController::class, 'approveRequest']);
    Route::put('/extension-requests/{requestId}/reject', [ExtensionRequestController::class, 'rejectRequest']);

    // ===== NOTIFICATION ROUTES =====
    Route::get('/notifications', [NotificationController::class, 'getNotifications']);
    Route::get('/notifications/unread', [NotificationController::class, 'getUnreadNotifications']);
    Route::put('/notifications/{notificationId}/read', [NotificationController::class, 'markAsRead']);
    Route::put('/notifications/all/read', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{notificationId}', [NotificationController::class, 'deleteNotification']);
    Route::delete('/notifications', [NotificationController::class, 'deleteAllNotifications']);

    // ===== RECOMMENDATION ROUTES =====
    Route::get('/recommendations', [BookRecommendationController::class, 'getRecommendations']);
    Route::post('/recommendations/refresh', [BookRecommendationController::class, 'refreshRecommendations']);
});