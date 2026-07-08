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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.av_timer_rounded, color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Perpanjang Buku',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Durasi Perpanjangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedDays,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                const SizedBox(height: 18),
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
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
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
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
        return const Color(0xFF4F46E5).withOpacity(0.08);
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
      backgroundColor: const Color(0xFFF8FAFC), // Modern Slate Light
      appBar: AppBar(
        title: const Text(
          'Riwayat Peminjaman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF1E1B4B)], // Premium Slate Indigo Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _peminjamanList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 60, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data dari server.\nPastikan koneksi internet aktif dan backend berjalan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada riwayat peminjaman materi.',
                    style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final peminjamans = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(18),
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

              int estimatedFine = 0;
              bool isOverdue = false;
              if (status.toLowerCase() == 'dipinjam' || status.toLowerCase() == 'pending_kembali') {
                estimatedFine = _calculateEstimatedFine(dueDate);
                if (estimatedFine > 0) {
                  isOverdue = true;
                }
              }

              final bool showReturnButton = status.toLowerCase() == 'dipinjam';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          width: 6,
                          color: isOverdue
                              ? const Color(0xFFEF4444)
                              : (status.toLowerCase() == 'dipinjam'
                                  ? const Color(0xFF4F46E5)
                                  : (status.toLowerCase() == 'pending_kembali'
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981))),
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusColor(status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status.toLowerCase() == 'dipinjam'
                                    ? const Color(0xFF4F46E5)
                                    : (status.toLowerCase() == 'pending_kembali'
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF059669)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                'Jatuh Tempo: $dueDate',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (denda > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Denda: Rp${denda.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isOverdue) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.report_problem_outlined, color: Colors.amber.shade800, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Estimasi Denda: Rp${estimatedFine.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Segera kembalikan buku ke perpustakaan untuk membatasi denda.',
                                    style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (showReturnButton) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _requestExtension(pem['id'], title),
                                  icon: const Icon(Icons.av_timer_rounded, size: 16),
                                  label: const Text(
                                    'Perpanjang',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF4F46E5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _requestReturn(pem['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
