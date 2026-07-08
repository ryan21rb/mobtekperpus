import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/petugas_drawer.dart';

class PetugasExtensionRequestsScreen extends StatefulWidget {
  const PetugasExtensionRequestsScreen({Key? key}) : super(key: key);

  @override
  State<PetugasExtensionRequestsScreen> createState() =>
      _PetugasExtensionRequestsScreenState();
}

class _PetugasExtensionRequestsScreenState
    extends State<PetugasExtensionRequestsScreen> {
  late ApiService _apiService;
  final AuthService _authService = AuthService();
  late Future<List<dynamic>> _pendingRequests;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadPendingRequests();
  }

  void _loadPendingRequests() {
    final token = _authService.getToken() ?? '';
    _pendingRequests = _apiService.getPendingExtensionRequests(token);
  }

  void _processRequest(int requestId, bool approve) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
              const SizedBox(height: 16),
              Text(
                approve ? 'Menyetujui perpanjangan...' : 'Menolak perpanjangan...',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );

    final token = _authService.getToken() ?? '';
    final result = approve
        ? await _apiService.approveExtensionRequest(token, requestId)
        : await _apiService.rejectExtensionRequest(token, requestId);

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      _showSnackBar(
        result['message'] ?? 'Permintaan berhasil diproses',
        result['success'] ? Colors.green : Colors.red,
      );

      if (result['success']) {
        setState(() {
          _loadPendingRequests();
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    const Color temaIndigo = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern Slate Light
      appBar: AppBar(
        title: const Text(
          'Persetujuan Perpanjangan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.3),
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const PetugasDrawer(currentRoute: '/petugas-extension-requests'),
      body: FutureBuilder<List<dynamic>>(
        future: _pendingRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: temaIndigo),
                  SizedBox(height: 16),
                  Text('Memuat antrian perpanjangan...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _loadPendingRequests();
                });
              },
              child: ListView(
                children: const [
                  SizedBox(height: 150),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.done_all_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada permintaan perpanjangan pending.',
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadPendingRequests();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                final pem = req['peminjaman'] ?? {};
                final bookTitle = pem['materi']?['title'] ?? 'Buku Tidak Diketahui';
                final borrowerName = pem['user']?['name'] ?? 'Nama Tidak Diketahui';
                final borrowerEmail = pem['user']?['email'] ?? '-';
                final curDueDate = pem['due_date'] ?? '-';
                final newDueDate = req['new_due_date'] ?? '-';
                final days = req['extension_days'] ?? 7;
                final reason = req['reason'] ?? '-';

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
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 6,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Request ID: #${req['id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: Text(
                                    'PENDING',
                                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              bookTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Peminjam: $borrowerName ($borrowerEmail)',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.date_range_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      children: [
                                        const TextSpan(text: 'Jatuh Tempo: '),
                                        TextSpan(
                                          text: curDueDate,
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(text: ' ➔ '),
                                        TextSpan(
                                          text: newDueDate,
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: ' (+$days Hari)',
                                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Alasan: "$reason"',
                                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _processRequest(req['id'], false),
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.4)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _processRequest(req['id'], true),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                },
              ),
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
