import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../widgets/petugas_drawer.dart';

class PetugasHistoryScreen extends StatefulWidget {
  const PetugasHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PetugasHistoryScreen> createState() => _PetugasHistoryScreenState();
}

class _PetugasHistoryScreenState extends State<PetugasHistoryScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _listReturns = [];
  List<dynamic> _filteredReturns = [];
  bool _isLoading = true;

  int _totalReturnsCount = 0;
  int _totalFinesAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    try {
      final allData = await _apiService.getPeminjaman();

      // Filter data peminjaman yang berstatus kembali atau dikembalikan
      final returnData = allData.where((item) {
        String status = (item['status'] ?? '').toString().toLowerCase();
        return status == 'kembali' || status == 'dikembalikan';
      }).toList();

      int tempFines = 0;
      for (var item in returnData) {
        int denda = int.tryParse(item['denda']?.toString() ?? '0') ?? 0;
        tempFines += denda;
      }

      setState(() {
        _listReturns = returnData;
        _filteredReturns = returnData;
        _totalReturnsCount = returnData.length;
        _totalFinesAmount = tempFines;
        _isLoading = false;
      });
      _filterResults(_searchController.text);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Gagal memuat data riwayat: $e", Colors.red.shade600);
    }
  }

  void _filterResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredReturns = _listReturns;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredReturns = _listReturns.where((item) {
        final bookTitle = (item['book_title'] ?? '').toString().toLowerCase();
        final userName = (item['user_name'] ?? '').toString().toLowerCase();
        final trxId = (item['id'] ?? '').toString().toLowerCase();
        return bookTitle.contains(lowerQuery) ||
            userName.contains(lowerQuery) ||
            trxId.contains(lowerQuery);
      }).toList();
    });
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(amount);
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



  @override
  Widget build(BuildContext context) {
    const Color temaBiruGelap = Color(0xFF1A237E);
    bool isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Perpus - Riwayat Pengembalian',
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
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHistoryData,
          ),
        ],
      ),
      drawer: const PetugasDrawer(currentRoute: '/petugas-history'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(temaBiruGelap),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistoryData,
              color: temaBiruGelap,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. STATS WIDGET HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [temaBiruGelap, temaBiruGelap.withOpacity(0.85)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "SUDAH KEMBALI",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$_totalReturnsCount Buku",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "DENDA TERKUMPUL",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.monetization_on, color: Colors.yellow, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatCurrency(_totalFinesAmount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. SEARCH BAR CARD
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterResults,
                          decoration: InputDecoration(
                            hintText: "Cari berdasarkan Judul Buku, Peminjam, atau ID...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: temaBiruGelap),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterResults('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. DATA TABLE CARD
                    const Text(
                      "Data Riwayat Pengembalian",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: temaBiruGelap,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _filteredReturns.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  "Tidak ditemukan riwayat pengembalian.",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
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
                                  width: isWideScreen
                                      ? MediaQuery.of(context).size.width - 32
                                      : 850, // Minimum width for mobile scroll
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(temaBiruGelap),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('No', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('ID Trx', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('Buku', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('Peminjam', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('Tgl Pinjam', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('Tgl Kembali', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('Denda', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                                    ],
                                    rows: List.generate(_filteredReturns.length, (index) {
                                      final item = _filteredReturns[index];
                                      int denda = int.tryParse(item['denda']?.toString() ?? '0') ?? 0;

                                      return DataRow(
                                        cells: [
                                          DataCell(Text('${index + 1}')),
                                          DataCell(Text('#${item['id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                          DataCell(
                                            Container(
                                              constraints: const BoxConstraints(maxWidth: 220),
                                              child: Text(
                                                item['book_title'] ?? '-',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(item['user_name'] ?? '-')),
                                          DataCell(Text(item['date'] ?? item['created_at']?.toString().split('T').first ?? '-')),
                                          DataCell(Text(item['returned_at'] ?? '-')),
                                          DataCell(
                                            Text(
                                              denda > 0 ? _formatCurrency(denda) : 'Bebas Denda',
                                              style: TextStyle(
                                                color: denda > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                                fontWeight: denda > 0 ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Chip(
                                              label: const Text(
                                                "KEMBALI",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              backgroundColor: Colors.green.shade50,
                                              side: BorderSide.none,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  ],
                ),
              ),
            ),
    );
  }
}
