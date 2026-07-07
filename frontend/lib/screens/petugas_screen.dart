import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/petugas_drawer.dart';

class PetugasScreen extends StatefulWidget {
  const PetugasScreen({super.key});

  @override
  State<PetugasScreen> createState() => _PetugasScreenState();
}

class _PetugasScreenState extends State<PetugasScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<dynamic> _listPeminjaman = [];
  bool _isLoading = true;

  // Variabel untuk counter ringkasan (Dashboard Mini)
  int _totalDipinjam = 0;
  int _totalKembali = 0;

  @override
  void initState() {
    super.initState();
    _loadDataPetugas();
  }

  // Mengambil data peminjaman dari Laravel dan menghitung ringkasan status
  Future<void> _loadDataPetugas() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getPeminjaman();

      int dipinjamCounter = 0;
      int kembaliCounter = 0;

      if (data != null) {
        for (var item in data) {
          String status = (item['status'] ?? '').toString().toLowerCase();
          if (status == 'dipinjam') {
            dipinjamCounter++;
          } else if (status == 'kembali' || status == 'disetujui') {
            kembaliCounter++;
          }
        }
      }

      setState(() {
        _listPeminjaman = data ?? [];
        _totalDipinjam = dipinjamCounter;
        _totalKembali = kembaliCounter;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Gagal memuat data: $e", Colors.red.shade600);
    }
  }

  // Fungsi mengubah status transaksi oleh petugas
  void _handleUpdateStatus(dynamic id, String currentStatus) async {
    String statusBaru = currentStatus.toLowerCase() == 'dipinjam'
        ? 'kembali'
        : 'dipinjam';

    // Memanggil fungsi update status di ApiService kamu
    bool success = await _apiService.updatePinjamStatus(id, statusBaru);

    if (success) {
      _loadDataPetugas(); // Refresh data biar langsung berubah di layar
      _showSnackBar(
        "Status peminjaman berhasil diperbarui menjadi ${statusBaru.toUpperCase()}!",
        Colors.green.shade700,
      );
    } else {
      _showSnackBar(
        "Gagal memperbarui status transaksi ke Laravel.",
        Colors.red.shade600,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    final isSuccess =
        color == Colors.green || color.value == Colors.green.value;
    final isError =
        color == Colors.red ||
        color.value == Colors.red.shade600.value ||
        color.value == Colors.redAccent.value;
    final isWarning =
        color == Colors.orange ||
        color == Colors.orangeAccent ||
        color == Colors.amber;
    CustomToast.show(
      context,
      message,
      isSuccess: isSuccess,
      isError: isError,
      isWarning: isWarning,
    );
  }


  @override
  Widget build(BuildContext context) {
    // TEMA UTAMA: Biru Gelap yang disamain dengan halaman Login & Regis
    const Color temaBiruGelap = Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perpus - Panel Petugas',
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const PetugasDrawer(currentRoute: '/petugas'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(temaBiruGelap),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDataPetugas,
              color: temaBiruGelap,
              child: Column(
                children: [
                  // 1. HEADER DASHBOARD MINI (Berisi Counter Angka Transaksi)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Kotak Ringkasan Buku Dipinjam
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "SEDANG DIPINJAM",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$_totalDipinjam Buku",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Kotak Ringkasan Buku Dikembalikan
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "SUDAH KEMBALI",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$_totalKembali Buku",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Teks Judul Daftar Transaksi
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Daftar Request Log Peminjaman",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: temaBiruGelap,
                        ),
                      ),
                    ),
                  ),

                  // 2. LIST DATA TRANSAKSI PEMINJAMAN
                  Expanded(
                    child: _listPeminjaman.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  "Belum ada data aktivitas peminjaman.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            itemCount: _listPeminjaman.length,
                            itemBuilder: (context, index) {
                              final item = _listPeminjaman[index];
                              final String currentStatus =
                                  item['status'] ?? 'Dipinjam';
                              final bool isDipinjam =
                                  currentStatus.toLowerCase() == 'dipinjam';

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Trx ID: #${item['id'] ?? '0'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDipinjam
                                                  ? Colors.orange.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.green.withOpacity(
                                                      0.2,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              currentStatus.toUpperCase(),
                                              style: TextStyle(
                                                color: isDipinjam
                                                    ? Colors.orange.shade800
                                                    : Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      // Baris Informasi Peminjam
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.account_circle,
                                            color: temaBiruGelap,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Anggota: ${item['user_name'] ?? item['user']?['name'] ?? 'Nama Tidak Diketahui'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Baris Informasi Buku
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.menu_book,
                                            color: temaBiruGelap,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Buku: ${item['book_title'] ?? item['materi_title'] ?? 'Judul Tidak Diketahui'}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Baris Informasi Tanggal Pinjam
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.date_range,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Tanggal: ${item['date'] ?? item['tanggal_pinjam'] ?? '-'}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Tombol Ubah Status
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _handleUpdateStatus(
                                            item['id'],
                                            currentStatus,
                                          ),
                                          icon: Icon(
                                            isDipinjam
                                                ? Icons.check_circle_outline
                                                : Icons.replay,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isDipinjam
                                                ? "Konfirmasi Pengembalian"
                                                : "Set Jadi Dipinjam Lagi",
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: temaBiruGelap,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
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
                ],
              ),
            ),
    );
  }
}
