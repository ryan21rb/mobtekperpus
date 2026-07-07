# 📱 IMPLEMENTASI FLUTTER - IWU Library Fitur Verifikasi Pengembalian

---

## Update ApiService di Flutter

**File**: `frontend/lib/services/api_service.dart` - Tambahkan method-method berikut:

```dart
// ============ PEMINJAMAN ENDPOINTS ============

/// GET /api/peminjaman/pending-return
/// Ambil list peminjaman yang pending dikembalikan (untuk petugas)
Future<List<dynamic>> getPendingReturns() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/peminjaman/pending-return'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    } else {
      throw Exception('Gagal mengambil data pending returns');
    }
  } catch (e) {
    print('Error getPendingReturns: $e');
    rethrow;
  }
}

/// GET /api/peminjaman/user/{userId}
/// Ambil data peminjaman user tertentu
Future<List<dynamic>> getUserPeminjaman(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/peminjaman/user/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    } else {
      throw Exception('Gagal mengambil data peminjaman user');
    }
  } catch (e) {
    print('Error getUserPeminjaman: $e');
    rethrow;
  }
}

/// POST /api/peminjaman/request-return
/// User request pengembalian buku (ubah status ke pending_kembali)
Future<bool> requestReturn(int peminjamanId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/peminjaman/request-return'),
      headers: _headers,
      body: jsonEncode({
        'peminjaman_id': peminjamanId,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['success'] ?? false;
    } else {
      throw Exception('Gagal membuat request pengembalian');
    }
  } catch (e) {
    print('Error requestReturn: $e');
    rethrow;
  }
}

/// POST /api/peminjaman/{id}/verify-return
/// Petugas verifikasi pengembalian & hitung denda otomatis
Future<Map<String, dynamic>> verifyReturn(int peminjamanId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/peminjaman/$peminjamanId/verify-return'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? {};
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Gagal memverifikasi pengembalian');
    }
  } catch (e) {
    print('Error verifyReturn: $e');
    rethrow;
  }
}

/// POST /api/peminjaman
/// Create peminjaman manual (untuk admin)
Future<bool> createPeminjaman(int userId, int materiId, {int? daysDuration}) async {
  try {
    final body = {
      'user_id': userId,
      'materi_id': materiId,
    };

    if (daysDuration != null) {
      body['days_duration'] = daysDuration;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/peminjaman'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['success'] ?? false;
    } else {
      throw Exception('Gagal membuat peminjaman');
    }
  } catch (e) {
    print('Error createPeminjaman: $e');
    rethrow;
  }
}
```

---

## Screens untuk User (Mahasiswa)

**File**: `frontend/lib/screens/user_peminjaman_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class UserPeminjamanScreen extends StatefulWidget {
  const UserPeminjamanScreen({Key? key}) : super(key: key);

  @override
  State<UserPeminjamanScreen> createState() => _UserPeminjamanScreenState();
}

class _UserPeminjamanScreenState extends State<UserPeminjamanScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<dynamic> _peminjamans = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() => _userId = user['id']);
        await _loadPeminjamans();
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data user', Colors.red);
    }
  }

  Future<void> _loadPeminjamans() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getUserPeminjaman(_userId!);
      setState(() {
        _peminjamans = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat peminjaman: $e', Colors.red);
    }
  }

  Future<void> _handleReturnRequest(int peminjamanId, String bookTitle) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pengembalian'),
        content: Text('Kembalikan buku "$bookTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Mengirim permintaan...');

              try {
                final success = await _apiService.requestReturn(peminjamanId);
                Navigator.pop(context); // Tutup loading dialog

                if (success) {
                  _showSnackBar(
                    'Permintaan pengembalian telah dikirim ke petugas',
                    Colors.green,
                  );
                  _loadPeminjamans(); // Refresh
                } else {
                  _showSnackBar('Gagal mengirim permintaan', Colors.red);
                }
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Kirim Permintaan'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Saya'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _peminjamans.isEmpty
              ? const Center(
                  child: Text('Anda belum meminjam buku apapun'),
                )
              : RefreshIndicator(
                  onRefresh: _loadPeminjamans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _peminjamans.length,
                    itemBuilder: (context, index) {
                      final item = _peminjamans[index];
                      final String status = item['status'] ?? 'dipinjam';
                      final String bookTitle = item['materi']['title'] ?? 'Unknown';
                      final String dueDate = item['due_date'] ?? '-';
                      final bool isPending = status == 'pending_kembali';
                      final bool isDipinjam = status == 'dipinjam';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      bookTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDipinjam
                                          ? Colors.blue.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDipinjam
                                            ? Colors.blue.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kembalikan sebelum: $dueDate',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isDipinjam)
                                ElevatedButton(
                                  onPressed: () => _handleReturnRequest(
                                    item['id'],
                                    bookTitle,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    minimumSize:
                                        const Size(double.infinity, 36),
                                  ),
                                  child: const Text('Kembalikan Buku'),
                                )
                              else if (isPending)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Menunggu verifikasi petugas...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
```

---

## Screens untuk Petugas (Return Verification Queue)

**File**: `frontend/lib/screens/petugas_return_queue_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PetugasReturnQueueScreen extends StatefulWidget {
  const PetugasReturnQueueScreen({Key? key}) : super(key: key);

  @override
  State<PetugasReturnQueueScreen> createState() =>
      _PetugasReturnQueueScreenState();
}

class _PetugasReturnQueueScreenState extends State<PetugasReturnQueueScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _pendingReturns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingReturns();
  }

  Future<void> _loadPendingReturns() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getPendingReturns();
      setState(() {
        _pendingReturns = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat data: $e', Colors.red);
    }
  }

  Future<void> _handleVerifyReturn(dynamic item) async {
    final peminjamanId = item['id'];
    final bookTitle = item['materi']['title'] ?? 'Unknown';
    final userName = item['user']['name'] ?? 'Unknown';
    final daysLate = item['days_late'] ?? 0;
    final estimatedFine = item['estimated_fine'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Pengembalian Buku'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Buku', bookTitle),
              _buildInfoRow('Peminjam', userName),
              _buildInfoRow('Hari Terlambat', '$daysLate hari'),
              _buildInfoRow(
                'Denda',
                'Rp ${estimatedFine.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                color: estimatedFine > 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog('Memproses verifikasi...');

              try {
                final result = await _apiService.verifyReturn(peminjamanId);
                Navigator.pop(context); // Tutup loading dialog

                _showSnackBar(
                  'Pengembalian berhasil diverifikasi${result['total_fine'] > 0 ? ' - Denda: Rp ${result['total_fine']}' : ''}',
                  Colors.green,
                );

                _loadPendingReturns(); // Refresh list
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Setujui Pengembalian'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean Pengembalian Buku'),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingReturns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak ada pengembalian pending',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingReturns,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pendingReturns.length,
                    itemBuilder: (context, index) {
                      final item = _pendingReturns[index];
                      final bookTitle =
                          item['materi']['title'] ?? 'Unknown';
                      final userName = item['user']['name'] ?? 'Unknown';
                      final daysLate = item['days_late'] ?? 0;
                      final estimatedFine = item['estimated_fine'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        color: daysLate > 0
                            ? Colors.red.shade50
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Header dengan status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bookTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Peminjam: $userName',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (daysLate > 0)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Text(
                                        '$daysLate hari terlambat',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Info denda
                              if (estimatedFine > 0)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Denda: Rp ${estimatedFine.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),

                              // Action button
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _handleVerifyReturn(item),
                                icon: const Icon(Icons.check),
                                label: const Text(
                                  'Setujui Pengembalian',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(
                                    double.infinity,
                                    40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
```

---

---
