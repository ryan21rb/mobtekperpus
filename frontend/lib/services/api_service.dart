import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Gunakan localhost agar CORS tidak blocked (match dengan browser origin)
  final String baseUrl = "http://localhost:8000/api";
  // final String baseUrl = "http://172.26.209.75:8000/api";
  // Ubah jadi seperti ini:
  // final String baseUrl = "http://192.168.1.5:8000/api";
  // ================= 1. ENDPOINT BUKU / MATERI =================

  // Ambil Semua Data Materi (GET)
  Future<List<dynamic>> getMateri() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materi"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("Gagal mengambil materi: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getMateri: $e");
      return [];
    }
  }

  // Tambah Materi (POST Multipart)
  Future<bool> createMateri({
    required String title,
    required String description,
    int? stock,
    String? category,
    String? author,
    int? publicationYear,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/materi");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.fields['title'] = title;
      request.fields['description'] = description;
      if (stock != null) {
        request.fields['stock'] = stock.toString();
      }
      if (category != null) {
        request.fields['category'] = category;
      }
      if (author != null) {
        request.fields['author'] = author;
      }
      if (publicationYear != null) {
        request.fields['publication_year'] = publicationYear.toString();
      }

      if (imageBytes != null && imageName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: imageName,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Gagal membuat materi. Status Code: ${response.statusCode}");
        print("Respon Server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error createMateri: $e");
      return false;
    }
  }

  // Update Materi (PUT Multipart via POST Spoofing)
  Future<bool> updateMateri({
    required int id,
    required String title,
    required String description,
    int? stock,
    String? category,
    String? author,
    int? publicationYear,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/materi/$id");
      var request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';
      request.fields['title'] = title;
      request.fields['description'] = description;
      if (stock != null) {
        request.fields['stock'] = stock.toString();
      }
      if (category != null) {
        request.fields['category'] = category;
      }
      if (author != null) {
        request.fields['author'] = author;
      }
      if (publicationYear != null) {
        request.fields['publication_year'] = publicationYear.toString();
      }

      if (imageBytes != null && imageName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: imageName,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Gagal memperbarui materi: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updateMateri: $e");
      return false;
    }
  }

  // Hapus Materi (DELETE)
  Future<bool> deleteMateri(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/materi/$id"),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleteMateri: $e");
      return false;
    }
  }

  // ================= 2. ENDPOINT USERS & ROLES =================

  // Ambil Semua Data Users dari DB (GET)
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("Gagal mengambil users: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getUsers: $e");
      return [];
    }
  }

  // Update Role User ke DB (PUT)
  Future<bool> updateUserRole(dynamic id, String role) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/users/$id/role"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': role}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updateUserRole: $e");
      return false;
    }
  }

  // Ambil Semua Data Transaksi Peminjaman (GET)
  Future<List<dynamic>> getPeminjaman() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/peminjaman"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("Gagal mengambil data peminjaman: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getPeminjaman: $e");
      return [];
    }
  }

  // 1. Ambil data antrian (pending_kembali) atau riwayat (dikembalikan)
  Future<List<dynamic>> getPeminjamanByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/peminjaman/status/$status"),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print(
          "Gagal mengambil data peminjaman status $status: ${response.body}",
        );
        return [];
      }
    } catch (e) {
      print("Error getPeminjamanByStatus: $e");
      return [];
    }
  }

  // 2. Aksi Petugas menyetujui pengembalian buku (Mengubah status ke 'dikembalikan')
  Future<Map<String, dynamic>> approveReturn(int peminjamanId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/peminjaman/$peminjamanId/approve-return"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pengembalian disetujui',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memproses pengembalian',
        };
      }
    } catch (e) {
      print("Error approveReturn: $e");
      return {'success': false, 'message': 'Terjadi kesalahan koneksi'};
    }
  }

  // Ubah Status Peminjaman Dipinjam/Kembali (PUT)
  Future<bool> updatePinjamStatus(dynamic id, String status) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/peminjaman/$id/status"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updatePinjamStatus: $e");
      return false;
    }
  }

  // Simpan data transaksi klik tombol "Pinjam" ke DB Laravel (POST)
  Future<bool> pinjamBuku(int materiId, {required String token, int? daysDuration}) async {
    try {
      final bodyMap = <String, dynamic>{
        'materi_id': materiId,
      };
      if (daysDuration != null) {
        bodyMap['days_duration'] = daysDuration;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/peminjaman"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Gagal meminjam. Status Code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error pinjamBuku: $e");
      return false;
    }
  }

  // Ambil data peminjaman pending return untuk petugas (GET)
  Future<List<dynamic>> getPendingReturns() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/peminjaman/pending-return"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      } else {
        print("Gagal mengambil pending returns: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getPendingReturns: $e");
      return [];
    }
  }

  // Ambil peminjaman user tertentu (GET)
  Future<List<dynamic>> getUserPeminjaman(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/peminjaman/user/$userId"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      } else {
        print("Gagal mengambil peminjaman user: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getUserPeminjaman: $e");
      return [];
    }
  }

  // User request pengembalian buku (POST) - Perlu Auth
  Future<Map<String, dynamic>> requestReturn(
    int peminjamanId, {
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/peminjaman/request-return"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'peminjaman_id': peminjamanId}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data'],
      };
    } catch (e) {
      print("Error requestReturn: $e");
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  // Petugas verify return dan hitung denda (POST)
  Future<Map<String, dynamic>> verifyReturn(int peminjamanId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/peminjaman/$peminjamanId/verify-return"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data'],
      };
    } catch (e) {
      print("Error verifyReturn: $e");
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  // Get Materi Details by ID (GET)
  Future<Map<String, dynamic>> getMateriById(String materiId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/peminjaman/materi/$materiId"),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data'],
      };
    } catch (e) {
      print("Error getMateriById: $e");
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  // ===== FITUR 1 & 2: REVIEWS & RATING =====
  Future<List<dynamic>> getBookReviews(int materiId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/reviews/materi/$materiId"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getBookReviews: $e");
      return [];
    }
  }

  Future<List<dynamic>> getUserReviews(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/reviews/my-reviews"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getUserReviews: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> createReview({
    required String token,
    required int materiId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reviews"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'materi_id': materiId,
          'rating': rating,
          'comment': comment,
        }),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data'],
      };
    } catch (e) {
      print("Error createReview: $e");
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  Future<bool> deleteReview({
    required String token,
    required int reviewId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/reviews/$reviewId"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleteReview: $e");
      return false;
    }
  }

  // ===== FITUR 3: FAVORIT / BOOKMARK =====
  Future<List<dynamic>> getUserFavorites(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/favorites"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getUserFavorites: $e");
      return [];
    }
  }

  Future<bool> isFavorite({
    required String token,
    required int materiId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/favorites/$materiId/check"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorite'] ?? false;
      }
      return false;
    } catch (e) {
      print("Error isFavorite: $e");
      return false;
    }
  }

  Future<bool> addFavorite({
    required String token,
    required int materiId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/favorites"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'materi_id': materiId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error addFavorite: $e");
      return false;
    }
  }

  Future<bool> removeFavorite({
    required String token,
    required int materiId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/favorites/$materiId"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error removeFavorite: $e");
      return false;
    }
  }

  // ===== FITUR 4: REQUEST PERPANJANGAN =====
  Future<List<dynamic>> getMyExtensionRequests(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/extension-requests/my-requests"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getMyExtensionRequests: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> createExtensionRequest({
    required String token,
    required int peminjamanId,
    required int extensionDays,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/extension-requests"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'peminjaman_id': peminjamanId,
          'extension_days': extensionDays,
          'reason': reason,
        }),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data'],
      };
    } catch (e) {
      print("Error createExtensionRequest: $e");
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  Future<List<dynamic>> getPendingExtensionRequests(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/extension-requests/pending"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getPendingExtensionRequests: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> approveExtensionRequest(String token, int requestId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/extension-requests/$requestId/approve"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Berhasil menyetujui perpanjangan',
      };
    } catch (e) {
      print("Error approveExtensionRequest: $e");
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> rejectExtensionRequest(String token, int requestId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/extension-requests/$requestId/reject"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Berhasil menolak perpanjangan',
      };
    } catch (e) {
      print("Error rejectExtensionRequest: $e");
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  // ===== FITUR 1: NOTIFIKASI =====
  Future<List<dynamic>> getNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/notifications"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getNotifications: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getUnreadNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/notifications/unread"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'unread_count': data['unread_count'] ?? 0,
          'data': data['data'] ?? [],
        };
      }
      return {'success': false, 'unread_count': 0, 'data': []};
    } catch (e) {
      print("Error getUnreadNotifications: $e");
      return {'success': false, 'unread_count': 0, 'data': []};
    }
  }

  Future<bool> markNotificationAsRead({
    required String token,
    required int notificationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/notifications/$notificationId/read"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error markNotificationAsRead: $e");
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/notifications/all/read"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error markAllNotificationsAsRead: $e");
      return false;
    }
  }

  // ===== FITUR 6: PROFIL USER & STATISTIK =====
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'data': null};
    } catch (e) {
      print("Error getUserProfile: $e");
      return {'success': false, 'data': null};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/profile"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? '',
        'token': data['token'],
        'data': data['data']
      };
    } catch (e) {
      print("Error updateUserProfile: $e");
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile/stats"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'data': null};
    } catch (e) {
      print("Error getUserStats: $e");
      return {'success': false, 'data': null};
    }
  }

  Future<Map<String, dynamic>?> getLaporanSummary() async {
    try {
      // Sesuaikan URL base API dengan project Anda
      final response = await http.get(
        Uri.parse('\$baseUrl/laporan/summary'),
        headers: {
          'Authorization': 'Bearer \$token', // Jika membutuhkan token login
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print("Error getLaporanSummary: \$e");
      return null;
    }
  }

  Future<List<dynamic>> getBorrowingHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile/history"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getBorrowingHistory: $e");
      return [];
    }
  }

  Future<List<dynamic>> getCurrentBorrowings(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile/current-borrowings"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getCurrentBorrowings: $e");
      return [];
    }
  }

  // ===== FITUR 5: SEARCH & FILTER =====
  Future<Map<String, dynamic>> searchBooks({
    String? keyword,
    String? category,
    String? author,
    int? year,
    double? minRating,
    String? sortBy,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (keyword != null) params['keyword'] = keyword;
      if (category != null) params['category'] = category;
      if (author != null) params['author'] = author;
      if (year != null) params['year'] = year;
      if (minRating != null) params['min_rating'] = minRating;
      if (sortBy != null) params['sort_by'] = sortBy;
      params['limit'] = limit;

      final uri = Uri.parse(
        "$baseUrl/materi/search",
      ).replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': data['data'] ?? [],
          'pagination': data['pagination'],
          'filters': data['filters'],
        };
      }
      return {
        'success': false,
        'data': [],
        'pagination': null,
        'filters': null,
      };
    } catch (e) {
      print("Error searchBooks: $e");
      return {
        'success': false,
        'data': [],
        'pagination': null,
        'filters': null,
      };
    }
  }

  Future<List<dynamic>> getBookCategories() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materi/categories"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getBookCategories: $e");
      return [];
    }
  }

  Future<List<dynamic>> getBookAuthors() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materi/authors"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getBookAuthors: $e");
      return [];
    }
  }

  Future<List<dynamic>> getPublicationYears() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materi/years"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getPublicationYears: $e");
      return [];
    }
  }

  Future<List<dynamic>> getPopularBooks({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materi/popular?limit=$limit"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getPopularBooks: $e");
      return [];
    }
  }

  Future<List<dynamic>> getNewestBooks({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materi/newest?limit=$limit"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getNewestBooks: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getBookDetail(int materiId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materi/$materiId"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'data': null};
    } catch (e) {
      print("Error getBookDetail: $e");
      return {'success': false, 'data': null};
    }
  }

  // ===== FITUR 7: REKOMENDASI BUKU =====
  Future<List<dynamic>> getRecommendations(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/recommendations"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getRecommendations: $e");
      return [];
    }
  }

  Future<bool> refreshRecommendations(String token) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/recommendations/refresh"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error refreshRecommendations: $e");
      return false;
    }
  }

  // ===== CATEGORY CRUD APIs =====
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/categories"),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getCategories: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/categories"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'message': data['message'] ?? 'Berhasil menambahkan kategori',
        'data': data['data'],
      };
    } catch (e) {
      print("Error createCategory: $e");
      return {'success': false, 'message': 'Gagal menambahkan kategori: $e'};
    }
  }

  Future<Map<String, dynamic>> updateCategory(int id, String name) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/categories/$id"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Berhasil memperbarui kategori',
        'data': data['data'],
      };
    } catch (e) {
      print("Error updateCategory: $e");
      return {'success': false, 'message': 'Gagal memperbarui kategori: $e'};
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/categories/$id"),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleteCategory: $e");
      return false;
    }
  }

  Future<List<dynamic>> getSystemActivities(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/activities"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print("Error getSystemActivities: $e");
      return [];
    }
  }
}

