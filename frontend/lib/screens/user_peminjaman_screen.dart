import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class UserPeminjamanScreen extends StatefulWidget {
  const UserPeminjamanScreen({super.key});

  @override
  State<UserPeminjamanScreen> createState() => _UserPeminjamanScreenState();
}

class _UserPeminjamanScreenState extends State<UserPeminjamanScreen> {
  late ApiService _apiService;
  late AuthService _authService;
  late Future<List<dynamic>> _peminjamanList;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _authService = AuthService();
    _loadPeminjaman();
  }

  void _loadPeminjaman() {
    _peminjamanList = _getPeminjamanUser();
  }

  Future<List<dynamic>> _getPeminjamanUser() async {
    try {
      final user = await _authService.getUser();
      if (user != null) {
        return await _apiService.getUserPeminjaman(user['id']);
      }
    } catch (e) {
      debugPrint("Error fetching peminjaman: $e");
    }
    return [];
  }

  void _requestReturn(int peminjamanId) async {
    final token = _authService.getToken();
    if (token == null) {
      if (mounted) {
        _showSnackBar('Token tidak valid. Silakan login ulang', Colors.red);
      }
      return;
    }

    final result = await _apiService.requestReturn(peminjamanId, token: token);
    if (mounted) {
      _showSnackBar(
        result['message'] ?? 'Proses pengembalian diperbarui',
        result['success'] == true ? Colors.green : Colors.red,
      );
      if (result['success'] == true) {
        setState(() {
          _loadPeminjaman();
        });
      }
    }
  }

  void _requestExtension(int peminjamanId, String bookTitle) {
    int selectedDays = 7;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.av_timer, color: Color(0xFF1A237E), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Perpanjang Buku',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Durasi Perpanjangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedDays,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [3, 7, 10, 14].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value Hari'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedDays = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alasan Perpanjangan (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tulis alasan Anda di sini...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final token = _authService.getToken();
                if (token == null) return;

                final result = await _apiService.createExtensionRequest(
                  token: token,
                  peminjamanId: peminjamanId,
                  extensionDays: selectedDays,
                  reason: reasonController.text,
                );

                if (mounted) {
                  _showSnackBar(
                    result['message'] ?? 'Permintaan terkirim',
                    result['success'] == true ? Colors.green : Colors.red,
                  );
                  if (result['success'] == true) {
                    setState(() {
                      _loadPeminjaman();
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kirim Permintaan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateEstimatedFine(String dueDateStr) {
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final today = DateTime.now();
      final cleanDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final cleanToday = DateTime(today.year, today.month, today.day);

      if (cleanToday.isAfter(cleanDueDate)) {
        final daysLate = cleanToday.difference(cleanDueDate).inDays;
        return daysLate * 10000;
      }
    } catch (e) {
      // ignore parsing errors
    }
    return 0;
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dipinjam':
        return 'Sedang Dipinjam';
      case 'pending_kembali':
        return 'Pending Pengembalian';
      case 'dikembalikan':
      case 'kembali':
        return 'Sudah Dikembalikan';
      default:
        return status;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'dipinjam':
        return const Color(0xFF1A237E).withOpacity(0.05);
      case 'pending_kembali':
        return Colors.orange.shade50;
      case 'dikembalikan':
      case 'kembali':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Peminjaman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _peminjamanList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Terjadi gangguan data backend (Error 500).\nPastikan query join tabel Peminjaman ke tabel Materi sudah benar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat peminjaman materi.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            );
          }

          final peminjamans = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: peminjamans.length,
            itemBuilder: (context, index) {
              final pem = peminjamans[index];
              final status = pem['status'] ?? 'Unknown';
              final dueDate = pem['due_date'] ?? '-';
              final denda = pem['denda'] ?? 0;

              String title = 'Tanpa Judul';
              if (pem['title'] != null) {
                title = pem['title'];
              } else if (pem['materi'] != null &&
                  pem['materi']['title'] != null) {
                title = pem['materi']['title'];
              } else if (pem['book'] != null && pem['book']['title'] != null) {
                title = pem['book']['title'];
              }

              // Hitung estimasi denda jika sedang dipinjam/pending dan terlambat
              int estimatedFine = 0;
              bool isOverdue = false;
              if (status.toLowerCase() == 'dipinjam' || status.toLowerCase() == 'pending_kembali') {
                estimatedFine = _calculateEstimatedFine(dueDate);
                if (estimatedFine > 0) {
                  isOverdue = true;
                }
              }

              final bool showReturnButton = status.toLowerCase() == 'dipinjam';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          width: 6,
                          color: isOverdue
                              ? Colors.red
                              : (status.toLowerCase() == 'dipinjam'
                                  ? const Color(0xFF1A237E)
                                  : (status.toLowerCase() == 'pending_kembali'
                                        ? Colors.orange
                                        : Colors.green)),
                        ),
                      ),
                    ),
                    child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusColor(status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: status.toLowerCase() == 'dipinjam'
                                ? const Color(0xFF1A237E)
                                : (status.toLowerCase() == 'pending_kembali'
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jatuh Tempo: $dueDate',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      if (denda > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Denda: Rp${denda.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ] else if (isOverdue) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.report_problem, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Estimasi Denda: Rp${estimatedFine.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Segera kembalikan buku ke perpustakaan untuk membatasi denda.',
                          style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (showReturnButton) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _requestExtension(pem['id'], title),
                              icon: const Icon(Icons.av_timer, size: 16),
                              label: const Text(
                                'Perpanjang',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1A237E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _requestReturn(pem['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text(
                                'Kembalikan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: null,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    final isSuccess = color == Colors.green || color.value == Colors.green.value;
    CustomToast.show(
      context,
      message,
      isSuccess: isSuccess,
      isError: !isSuccess,
    );
  }
}
