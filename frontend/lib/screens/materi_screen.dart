// === 1. TARUH SEMUA IMPORT DI PALING ATAS SINI ===
import 'dart:convert'; // Untuk memperbaiki error 'json'
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http; // Untuk memperbaiki error 'http'
import 'package:url_launcher/url_launcher.dart'; // Untuk fungsi launchUrl
import 'dart:html' as html; // Jika Anda compile untuk Flutter Web
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'admin_activity_screen.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // Penampung State List Data
  List<dynamic> _listMateri = [];
  List<dynamic> _listUsers = [];
  List<dynamic> _listPinjam = [];
  List<dynamic> _listCategories = [];
  Map<String, dynamic> _dataLaporanSummary = {};
  List<dynamic> _laporanTransaksi = [];

  bool _isLoading = true;
  int _currentIndex =
      0; // Mengontrol Bottom Navigation (0: Buku, 1: User, 2: Pinjam)

  String? _userName;
  String? _userEmail;

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    final filename = imagePath.contains('/')
        ? imagePath.split('/').last
        : imagePath;
    return '${_apiService.baseUrl}/materi/image/$filename';
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _fetchPeminjaman(); // <--- Pastikan baris ini ada ya, Bang!
    ambilDataDashboard(); // Panggil fungsi ini saat halaman pertama kali dimuat
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      if (mounted && user != null) {
        setState(() {
          _userName = user['name'];
          _userEmail = user['email'];
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> eksporExcelWeb() async {
    final Uri url = Uri.parse('http://localhost:8000/api/ekspor-excel');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showSnackBar('Gagal membuka link Excel', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', Colors.red);
    }
  }

  // 2. FUNGSI EKSPOR PDF
  Future<void> eksporPDFWeb() async {
    final Uri url = Uri.parse('http://localhost:8000/api/ekspor-pdf');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showSnackBar('Gagal membuka link PDF', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', Colors.red);
    }
  }

  // Pastikan fungsi fetch data laporan Anda di Flutter strukturnya seperti ini:
  Future<void> fetchLaporan() async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/peminjaman'),
    );
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        // Pastikan mengambil dari jsonResponse['data']
        _laporanTransaksi = jsonResponse['data'];
      });
    }
  }

  Future<void> _fetchPeminjaman() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '${_apiService.baseUrl}/peminjaman',
        ), // <--- Koma di sini tadi hilang Bang, sudah saya tambahkan!
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Log untuk monitoring di debug console
      print("=== STATUS CODE: ${response.statusCode} ===");
      print("=== DATA DARI LARAVEL ===");
      print(response.body);
      print("=========================");

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        setState(() {
          _laporanTransaksi = List<Map<String, dynamic>>.from(jsonResponse);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("Gagal mengambil data, status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error pas fetch data peminjaman: $e");
    }
  }

  Future<void> ambilDataDashboard() async {
    try {
      // Sesuaikan URL dengan endpoint API backend tempat Anda mengambil data summary & transaksi
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/dashboard-laporan'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dataLaporanSummary = data['summary'];
          _laporanTransaksi = data['transaksi'];
        });
      }
    } catch (e) {
      print("Error mengambil data: $e");
    }
  }

  // Sinkronisasi data utama dari 4 endpoint API sekaligus
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final materiData = await _apiService.getMateri();
      final userData = await _apiService.getUsers();
      final pinjamData = await _apiService.getPeminjaman();
      final categoriesData = await _apiService.getCategories();
      // Panggil service laporan baru
      final laporanData = await _apiService.getLaporanSummary();

      setState(() {
        _listMateri = materiData;
        _listUsers = userData;
        _listPinjam = pinjamData;
        _listCategories = categoriesData;

        if (laporanData != null && laporanData['success'] == true) {
          _dataLaporanSummary = laporanData['summary'] ?? {};
          _laporanTransaksi = laporanData['latest_transactions'] ?? [];
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Gagal memuat data dari server: $e", Colors.red.shade600);
    }
  }

  Widget _buildExportButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: eksporPDFWeb,
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            color: Colors.white,
            size: 16,
          ),
          label: const Text(
            "PDF",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: eksporExcelWeb,
          icon: const Icon(
            Icons.grid_on_outlined,
            color: Colors.white,
            size: 16,
          ),
          label: const Text(
            "Excel",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLaporanView() {
    final summary = _dataLaporanSummary;
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Judul & Tombol Ekspor Berdampingan (Responsif)
          isWideScreen
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ikhtisar Perpustakaan",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    _buildExportButtons(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ikhtisar Perpustakaan",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildExportButtons(),
                  ],
                ),
          const SizedBox(height: 24),

          // Grid Card Statistik yang responsif
          GridView.count(
            crossAxisCount: isWideScreen ? 4 : 2, // 4 Kolom di PC, 2 Kolom di HP
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isWideScreen ? 1.6 : 1.3,
            children: [
              _itemStatistik(
                title: "Total Buku",
                value: "${summary['total_buku'] ?? 0}",
                icon: Icons.menu_book_rounded,
                color: Colors.blue.shade700,
              ),
              _itemStatistik(
                title: "Total Anggota",
                value: "${summary['total_user'] ?? 0}",
                icon: Icons.people_alt_rounded,
                color: Colors.purple.shade700,
              ),
              _itemStatistik(
                title: "Sedang Dipinjam",
                value: "${summary['sedang_dipinjam'] ?? 0}",
                icon: Icons.bookmark_added_rounded,
                color: Colors.amber.shade800,
              ),
              _itemStatistik(
                title: "Sudah Kembali",
                value: "${summary['telah_kembali'] ?? 0}",
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade700,
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            "Log Aktivitas Transaksi Terbaru",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // List Transaksi dengan Style Elegan
          _laporanTransaksi.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Belum ada riwayat aktivitas sistem.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 2,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _laporanTransaksi.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey.shade100, height: 1),
                    itemBuilder: (context, index) {
                      final trx = _laporanTransaksi[index];
                      String rawStatus = trx['status'] ?? 'dipinjam';
                      bool isDipinjam = rawStatus.toLowerCase() == 'dipinjam';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isDipinjam
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          child: Icon(
                            isDipinjam
                                ? Icons.swap_horiz_rounded
                                : Icons.done_rounded,
                            color: isDipinjam
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                        title: Text(
                          trx['book_title'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Peminjam: ${trx['user_name'] ?? '-'}\nTanggal: ${trx['date'] ?? '-'}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        trailing: Chip(
                          label: Text(
                            isDipinjam ? "Dipinjam" : "Kembali",
                            style: TextStyle(
                              color: isDipinjam
                                  ? Colors.orange.shade900
                                  : Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: isDipinjam
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _itemStatistik({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(width: 6, color: color)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    final isSuccess = color == Colors.green || color.value == Colors.green.value;
    final isError = color == Colors.red || color.value == Colors.red.shade600.value || color.value == Colors.redAccent.value;
    final isWarning = color == Colors.orange || color == Colors.orangeAccent || color == Colors.amber;
    CustomToast.show(
      context,
      message,
      isSuccess: isSuccess,
      isError: isError,
      isWarning: isWarning,
    );
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Konfirmasi Logout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari Panel Admin?',
            style: TextStyle(color: Colors.black54),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                print("Proses logout dimulai...");

                // Hit API logout
                await _authService.logout();
                print("Logout berhasil, navigasi ke login...");

                if (mounted) {
                  // Gunakan rootNavigator untuk logout dari seluruh app
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
  // ================= ACTION HANDLERS =================

  Future<void> _toggleUserRole(Map<String, dynamic> user) async {
    String currentRole = user['role'] ?? 'User';
    String nextRole = currentRole == 'Admin'
        ? 'Petugas'
        : (currentRole == 'Petugas' ? 'User' : 'Admin');

    bool success = await _apiService.updateUserRole(user['id'], nextRole);
    if (success) {
      _showSnackBar(
        "Role ${user['name']} diubah menjadi $nextRole",
        Colors.green,
      );
      _loadAllData();
    } else {
      _showSnackBar("Gagal memperbarui role user.", Colors.red);
    }
  }

  Future<void> _togglePinjamStatus(Map<dynamic, dynamic> transaksi) async {
    String currentStatus = (transaksi['status'] ?? 'dipinjam').toString().toLowerCase();
    String nextStatus = currentStatus == 'dipinjam' ? 'kembali' : 'dipinjam';

    bool success = await _apiService.updatePinjamStatus(
      transaksi['id'],
      nextStatus,
    );
    if (success) {
      _showSnackBar(
        "Status transaksi diperbarui ke ${nextStatus.toUpperCase()}",
        const Color(0xFF1A237E),
      );
      _loadAllData();
    } else {
      _showSnackBar("Gagal memperbarui status transaksi ke DB.", Colors.red);
    }
  }

  // ================= MODAL FORM BUKU / MATERI =================

  void _showMateriForm({Map<String, dynamic>? materi}) {
    final titleController = TextEditingController(
      text: materi != null ? materi['title'] : '',
    );
    final descController = TextEditingController(
      text: materi != null ? materi['description'] : '',
    );
    final authorController = TextEditingController(
      text: materi != null ? (materi['author'] ?? '') : '',
    );
    final yearController = TextEditingController(
      text: materi != null ? (materi['publication_year'] ?? '').toString() : '',
    );
    final stockController = TextEditingController(
      text: materi != null ? (materi['stock'] ?? 1).toString() : '1',
    );
    String? selectedCategory = materi != null ? materi['category'] : null;
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible:
          false, // Mencegah modal tertutup tidak sengaja saat loading
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            materi == null ? "Tambah Koleksi Buku" : "Edit Koleksi Buku",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 500 ? 450 : double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Judul Buku",
                      prefixIcon: const Icon(Icons.book, color: Color(0xFF1A237E)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Deskripsi",
                      prefixIcon: const Icon(Icons.description, color: Color(0xFF1A237E)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    decoration: InputDecoration(
                      labelText: "Nama Pengarang",
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF1A237E)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory != null &&
                            _listCategories.any((cat) => cat['name'] == selectedCategory)
                        ? selectedCategory
                        : null,
                    decoration: InputDecoration(
                      labelText: "Kategori (Genre)",
                      prefixIcon: const Icon(Icons.category, color: Color(0xFF1A237E)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _listCategories.map<DropdownMenuItem<String>>((dynamic cat) {
                      return DropdownMenuItem<String>(
                        value: cat['name'] as String,
                        child: Text(cat['name'] as String),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedCategory = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: yearController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Tahun Terbit",
                            prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Stok Buku",
                            prefixIcon: const Icon(Icons.numbers, color: Color(0xFF1A237E)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.image, withData: true);

                      if (result != null && result.files.first.bytes != null) {
                        setModalState(() {
                          selectedImageBytes = result.files.first.bytes;
                          selectedImageName = result.files.first.name;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1A237E).withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_outlined, color: Color(0xFF1A237E)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              selectedImageName != null
                                  ? (selectedImageName!.length > 25
                                      ? "${selectedImageName!.substring(0, 22)}..."
                                      : selectedImageName!)
                                  : "Pilih Cover Gambar",
                              style: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (titleController.text.isEmpty ||
                          descController.text.isEmpty) {
                        _showSnackBar(
                          "Judul dan deskripsi tidak boleh kosong",
                          Colors.orange,
                        );
                        return;
                      }

                      if (yearController.text.isNotEmpty) {
                        final year = int.tryParse(yearController.text);
                        if (year == null || year < 1901 || year > 2155) {
                          _showSnackBar(
                            "Tahun Terbit harus berupa angka antara 1901 dan 2155",
                            Colors.orange,
                          );
                          return;
                        }
                      }

                      setModalState(() => isSaving = true);
                      bool success;

                      if (materi == null) {
                        success = await _apiService.createMateri(
                          title: titleController.text,
                          description: descController.text,
                          stock: int.tryParse(stockController.text) ?? 1,
                          category: selectedCategory,
                          author: authorController.text,
                          publicationYear: int.tryParse(yearController.text),
                          imageBytes: selectedImageBytes,
                          imageName: selectedImageName,
                        );
                      } else {
                        success = await _apiService.updateMateri(
                          id: materi['id'],
                          title: titleController.text,
                          description: descController.text,
                          stock: int.tryParse(stockController.text) ?? 1,
                          category: selectedCategory,
                          author: authorController.text,
                          publicationYear: int.tryParse(yearController.text),
                          imageBytes: selectedImageBytes,
                          imageName: selectedImageName,
                        );
                      }

                      if (success) {
                        if (mounted) Navigator.pop(context);
                        _showSnackBar(
                          "Data materi berhasil disimpan",
                          Colors.green,
                        );
                        _loadAllData();
                      } else {
                        setModalState(() => isSaving = false);
                        _showSnackBar(
                          "Terjadi kesalahan sistem di server backend.",
                          Colors.red,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INTERFACE WIDGET VIEWS =================

  Widget _buildBukuView() {
    if (_listMateri.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada data materi/buku di database.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth - 48;
        double tableWidth = availableWidth > 950 ? availableWidth : 950;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 2,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF1A237E)),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    dataRowMaxHeight: 80,
                    dataRowMinHeight: 60,
                    columns: const [
                      DataColumn(label: Text('No', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Cover', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Judul Buku', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Deskripsi', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Stok', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Aksi', style: TextStyle(color: Colors.white))),
                    ],
                    rows: List.generate(_listMateri.length, (index) {
                      final item = _listMateri[index];
                      final String? imagePath = item['image'];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                width: 45,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: imagePath != null && imagePath.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          _getImageUrl(imagePath),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                        ),
                                      )
                                    : const Icon(Icons.menu_book, size: 24, color: Colors.grey),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                item['title'] ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 350),
                              child: Text(
                                item['description'] ?? '-',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${item['stock'] ?? '0'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _showMateriForm(materi: item),
                                  tooltip: 'Edit Buku',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteConfirmation(item['id']),
                                  tooltip: 'Hapus Buku',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesView() {
    if (_listCategories.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada data kategori di database.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth - 48;
        double tableWidth = availableWidth > 600 ? availableWidth : 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 2,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF1A237E)),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    columns: const [
                      DataColumn(label: Text('No', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Nama Kategori', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Aksi', style: TextStyle(color: Colors.white))),
                    ],
                    rows: List.generate(_listCategories.length, (index) {
                      final item = _listCategories[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Text(
                              item['name'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _showCategoryForm(category: item),
                                  tooltip: 'Edit Kategori',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showCategoryDeleteConfirmation(item['id']),
                                  tooltip: 'Hapus Kategori',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryForm({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(
      text: category != null ? category['name'] : '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            category == null ? "Tambah Kategori" : "Edit Kategori",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 500 ? 400 : double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Nama Kategori",
                      prefixIcon: const Icon(Icons.category, color: Color(0xFF1A237E)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        _showSnackBar("Nama kategori tidak boleh kosong", Colors.orange);
                        return;
                      }

                      setModalState(() => isSaving = true);
                      Map<String, dynamic> res;

                      if (category == null) {
                        res = await _apiService.createCategory(nameController.text);
                      } else {
                        res = await _apiService.updateCategory(category['id'], nameController.text);
                      }

                      if (res['success'] == true) {
                        if (mounted) Navigator.pop(context);
                        _showSnackBar(
                          res['message'] ?? "Kategori berhasil disimpan",
                          Colors.green,
                        );
                        _loadAllData();
                      } else {
                        setModalState(() => isSaving = false);
                        _showSnackBar(
                          res['message'] ?? "Terjadi kesalahan sistem.",
                          Colors.red,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDeleteConfirmation(dynamic id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              "Hapus Kategori",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus kategori ini? Buku yang menggunakan kategori ini tidak akan terhapus, namun filter kategori akan terpengaruh.",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              bool ok = await _apiService.deleteCategory(id);
              if (ok) {
                _showSnackBar("Kategori berhasil dihapus", Colors.green);
                _loadAllData();
              } else {
                _showSnackBar(
                  "Gagal menghapus kategori dari server.",
                  Colors.red,
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmation(dynamic id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              "Hapus Koleksi",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus koleksi buku ini? Tindakan ini tidak dapat dibatalkan.",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              bool ok = await _apiService.deleteMateri(id);
              if (ok) {
                _showSnackBar("Koleksi buku berhasil dihapus", Colors.green);
                _loadAllData();
              } else {
                _showSnackBar(
                  "Gagal menghapus materi dari server.",
                  Colors.red,
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersView() {
    if (_listUsers.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada data user di database.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth - 48;
        double tableWidth = availableWidth > 900 ? availableWidth : 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 2,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF1A237E)),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    columns: const [
                      DataColumn(label: Text('No', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Nama', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Role', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Aksi', style: TextStyle(color: Colors.white))),
                    ],
                    rows: List.generate(_listUsers.length, (index) {
                      final user = _listUsers[index];
                      String role = user['role'] ?? 'User';
                      Color roleColor = Colors.grey;
                      if (role.toLowerCase() == 'admin') {
                        roleColor = Colors.red.shade700;
                      } else if (role.toLowerCase() == 'petugas') {
                        roleColor = Colors.blue.shade700;
                      } else {
                        roleColor = Colors.green.shade700;
                      }

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Text(
                              user['name'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text(user['email'] ?? '-')),
                          DataCell(
                            Chip(
                              label: Text(
                                role,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: roleColor,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide.none,
                            ),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              onPressed: () => _toggleUserRole(user),
                              icon: const Icon(Icons.cached, size: 16),
                              label: const Text('Ubah Role', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPeminjamanView() {
    if (_listPinjam.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada data log peminjaman buku.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth - 48;
        double tableWidth = availableWidth > 950 ? availableWidth : 950;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 2,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF1A237E)),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    columns: const [
                      DataColumn(label: Text('No', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Buku', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Peminjam', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Tanggal Pinjam', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Aksi', style: TextStyle(color: Colors.white))),
                    ],
                    rows: List.generate(_listPinjam.length, (index) {
                      final trx = _listPinjam[index];
                      String rawStatus = trx['status'] ?? 'Dipinjam';
                      bool isDipinjam = rawStatus.toLowerCase() == 'dipinjam';

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                trx['book_title'] ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(trx['user_name'] ?? '-')),
                          DataCell(Text(trx['date'] ?? '-')),
                          DataCell(
                            Chip(
                              label: Text(
                                isDipinjam ? "Dipinjam" : "Kembali",
                                style: TextStyle(
                                  color: isDipinjam ? Colors.orange.shade900 : Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: isDipinjam ? Colors.orange.shade100 : Colors.green.shade100,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide.none,
                            ),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              onPressed: () => _togglePinjamStatus(trx),
                              icon: Icon(
                                isDipinjam ? Icons.check_circle_outline : Icons.replay,
                                size: 16,
                              ),
                              label: Text(
                                isDipinjam ? "Set Kembali" : "Set Pinjam",
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDipinjam ? Colors.green.shade700 : Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_currentIndex == 0) return _buildBukuView();
    if (_currentIndex == 1) return _buildUsersView();
    if (_currentIndex == 2) return _buildPeminjamanView();
    if (_currentIndex == 3) return _buildLaporanView();
    if (_currentIndex == 4) return _buildCategoriesView();
    if (_currentIndex == 5) return const AdminActivityScreen();
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = "Perpus - Koleksi Buku";
    if (_currentIndex == 1) {
      appBarTitle = "Perpus - Data Anggota & Petugas";
    }
    if (_currentIndex == 2) {
      appBarTitle = "Perpus - Log Transaksi Peminjaman";
    }
    if (_currentIndex == 3) {
      appBarTitle = "Perpus - Laporan Sistem";
    }
    if (_currentIndex == 4) {
      appBarTitle = "Perpus - Data Kategori Buku";
    }
    if (_currentIndex == 5) {
      appBarTitle = "Perpus - Aktivitas Sistem";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllData,
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.only(top: 56, left: 24, right: 24, bottom: 24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Text(
                          (_userName != null && _userName!.isNotEmpty)
                              ? _userName![0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName ?? 'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail ?? 'admin@iwu.ac.id',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.15), // Gold badge capsule
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.book_rounded,
                      title: 'Data Buku',
                      index: 0,
                    ),
                    _buildDrawerItem(
                      icon: Icons.category_rounded,
                      title: 'Data Kategori',
                      index: 4,
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_rounded,
                      title: 'User & Role',
                      index: 1,
                    ),
                    _buildDrawerItem(
                      icon: Icons.assignment_rounded,
                      title: 'Peminjaman',
                      index: 2,
                    ),
                    _buildDrawerItem(
                      icon: Icons.assessment_rounded,
                      title: 'Laporan',
                      index: 3,
                    ),
                    _buildDrawerItem(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'Aktivitas Sistem',
                      index: 5,
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: const Icon(
                          Icons.person_rounded,
                          color: Colors.white60,
                          size: 22,
                        ),
                        title: const Text(
                          'Profil Saya',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Logout Button at Bottom
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Keluar Sistem',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF87171), // Soft Red Accent
                      side: BorderSide(color: const Color(0xFFF87171).withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showMateriForm(),
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : (_currentIndex == 4
              ? FloatingActionButton(
                  onPressed: () => _showCategoryForm(),
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white60,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.white.withOpacity(0.15),
        onTap: () {
          setState(() => _currentIndex = index);
          Navigator.pop(context); // Tutup drawer setelah memilih
        },
      ),
    );
  }
}
