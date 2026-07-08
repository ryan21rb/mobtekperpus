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
    const Color temaIndigo = Color(0xFF4F46E5);
    bool isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern Slate Light
      appBar: AppBar(
        title: const Text(
          'Riwayat Pengembalian',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadHistoryData,
          ),
        ],
      ),
      drawer: const PetugasDrawer(currentRoute: '/petugas-history'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(temaIndigo),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistoryData,
              color: temaIndigo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. STATS WIDGET HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF1E1B4B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$_totalReturnsCount Buku",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.monetization_on_rounded, color: Colors.yellow, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatCurrency(_totalFinesAmount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
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
                    const SizedBox(height: 24),

                    // 2. SEARCH BAR CONTAINER
                    Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterResults,
                        decoration: InputDecoration(
                          hintText: "Cari judul buku, peminjam, atau ID...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: temaIndigo),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
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
                    const SizedBox(height: 24),

                    // 3. DATA TABLE CARD
                    const Text(
                      "Data Riwayat Pengembalian",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _filteredReturns.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  "Tidak ditemukan riwayat pengembalian.",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(const Color(0xFF1E1B4B)),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('No')),
                                      DataColumn(label: Text('ID Trx')),
                                      DataColumn(label: Text('Buku')),
                                      DataColumn(label: Text('Peminjam')),
                                      DataColumn(label: Text('Tgl Pinjam')),
                                      DataColumn(label: Text('Tgl Kembali')),
                                      DataColumn(label: Text('Denda')),
                                      DataColumn(label: Text('Status')),
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
                                                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
                                                color: denda > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                fontWeight: denda > 0 ? FontWeight.bold : FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                "KEMBALI",
                                                style: TextStyle(
                                                  color: Color(0xFF059669),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
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
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
