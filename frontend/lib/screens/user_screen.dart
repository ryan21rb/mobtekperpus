import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'user_peminjaman_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  String get _apiBaseUrl {
    return 'http://localhost:8000/api';
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    final filename = imagePath.contains('/')
        ? imagePath.split('/').last
        : imagePath;
    return '$_apiBaseUrl/materi/image/$filename';
  }

  List<dynamic> _allBooks = [];
  List<dynamic> _filteredBooks = [];
  List<dynamic> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  final List<int> _borrowedBookIds = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_runLiveSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_runLiveSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<dynamic> bookData = await _apiService.getMateri();
      List<dynamic> categoryData = await _apiService.getCategories();
      final user = await _authService.getUser();
      List<int> backendBorrowedIds = [];

      if (user != null) {
        var peminjamanAktif = await _apiService.getPeminjaman();
        for (var item in peminjamanAktif) {
          if (item['user_id'] == user['id'] &&
              item['status'] != 'dikembalikan') {
            final bookId = item['book_id'] ?? item['materi_id'];
            if (bookId != null) {
              backendBorrowedIds.add(int.parse(bookId.toString()));
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _allBooks = bookData;
        _categories = categoryData;
        _borrowedBookIds.clear();
        _borrowedBookIds.addAll(backendBorrowedIds);
      });
      _runLiveSearch();
    } catch (e) {
      print("Error pas ambil data perpus: $e");
      if (!mounted) return;
      _showNotificationSnackBar(
        'Gagal memuat data dari server: $e',
        Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _runLiveSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        final title = book['title']?.toString().toLowerCase() ?? '';
        final description = book['description']?.toString().toLowerCase() ?? '';
        final category = book['category']?.toString() ?? '';
        
        final matchesQuery = title.contains(query) || description.contains(query);
        final matchesCategory = _selectedCategory == null || category == _selectedCategory;
        
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _handleBorrowAction(dynamic book) async {
    int bookId = book['id'];

    if (_borrowedBookIds.contains(bookId)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserPeminjamanScreen()),
      );
    } else {
      _showBorrowDurationDialog(book);
    }
  }

  void _showBorrowDurationDialog(dynamic book) {
    int bookId = book['id'];
    String bookTitle = book['title'] ?? 'Buku';
    int selectedDays = 7; 
    final customDaysController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              contentPadding: const EdgeInsets.all(24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.date_range, color: Color(0xFF1A237E), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pilih Durasi Pinjam',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buku: $bookTitle',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Berapa hari Anda ingin meminjam buku ini?',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [3, 7, 14].map((days) {
                      final isSelected = selectedDays == days;
                      return ChoiceChip(
                        label: Text('$days Hari'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedDays = days;
                              customDaysController.text = days.toString();
                            });
                          }
                        },
                        selectedColor: const Color(0xFF1A237E),
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customDaysController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0 && parsed <= 30) {
                        setModalState(() {
                          selectedDays = parsed;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Durasi Kustom (Maksimal 30 hari)",
                      hintText: "Masukkan jumlah hari",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: const Icon(Icons.edit_calendar, color: Color(0xFF1A237E)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final days = int.tryParse(customDaysController.text) ?? selectedDays;
                    if (days < 1 || days > 30) {
                      _showNotificationSnackBar('Durasi pinjam harus antara 1 sampai 30 hari.', Colors.orange);
                      return;
                    }
                    Navigator.pop(context);
                    _processBorrowAction(bookId, bookTitle, days);
                  },
                  child: const Text('Pinjam Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processBorrowAction(int bookId, String bookTitle, int durationDays) async {
    setState(() => _isLoading = true);
    final user = await _authService.getUser();
    final token = _authService.getToken();

    if (user == null || token == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showNotificationSnackBar(
        'User tidak ditemukan atau token tidak valid. Silakan login ulang',
        Colors.red.shade700,
      );
      return;
    }

    bool success = await _apiService.pinjamBuku(bookId, token: token, daysDuration: durationDays);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _borrowedBookIds.add(bookId);
      });
      _showNotificationSnackBar(
        'Berhasil meminjam: $bookTitle untuk $durationDays Hari',
        const Color(0xFF1A237E),
      );
      _loadInitialData();
    } else {
      _showNotificationSnackBar(
        'Gagal meminjam. Stok habis atau kuota penuh',
        Colors.red.shade700,
      );
    }
  }

  void _showBookDetail(dynamic book) {
    bool isBorrowed = _borrowedBookIds.contains(book['id']);
    String? imagePath = book['image'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SizedBox(
            width: 500,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 180,
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imagePath != null && imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _getImageUrl(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                          ),
                        )
                      : const Icon(
                          Icons.book,
                          size: 50,
                          color: Color(0xFF1A237E),
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book['title'] ?? 'Tanpa Judul',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text("Stok Tersedia: ${book['stock'] ?? '0'}"),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Deskripsi Lengkap:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book['description'] ??
                            'Tidak ada deskripsi mengenai materi ini.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleBorrowAction(book);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBorrowed
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isBorrowed ? 'Kembalikan Buku' : 'Pinjam Buku'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSnackBar(String message, Color color) {
    final isSuccess = color == Colors.green || color.value == Colors.green.value;
    final isWarning = color == Colors.orange || color.value == Colors.orange.value || color == Colors.amber;
    final isError = color == Colors.red || color.value == Colors.red.shade700.value;
    CustomToast.show(
      context,
      message,
      isSuccess: isSuccess,
      isWarning: isWarning,
      isError: isError,
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
            'Apakah Anda yakin ingin keluar dari Perpustakaan?',
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
                await _authService.logout();
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBooksView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang! 👋',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Temukan Koleksi Buku Terbaik',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari judul, penulis, atau kategori...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      hint: const Row(
                        children: [
                          Icon(Icons.category_outlined, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text("Pilih Kategori / Genre", style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.all_inclusive, color: Color(0xFF1A237E), size: 20),
                              SizedBox(width: 8),
                              Text("Semua Kategori", style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        ..._categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['name'] as String,
                            child: Row(
                              children: [
                                const Icon(Icons.label_outline, color: Color(0xFF1A237E), size: 20),
                                SizedBox(width: 8),
                                Text(cat['name'] as String),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _runLiveSearch();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Koleksi Buku Kami',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!_isLoading)
                      Text(
                        '${_filteredBooks.length} buku tersedia',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A237E),
                      ),
                    ),
                  )
                : _filteredBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Buku tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 24,
                        ),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      bool isBorrowed = _borrowedBookIds.contains(book['id']);
                      String? imagePath = book['image'];
                      return _buildBookCard(book, isBorrowed, imagePath);
                    },
                  ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildBookCard(dynamic book, bool isBorrowed, String? imagePath) {
    return GestureDetector(
      onTap: () => _showBookDetail(book),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: imagePath != null && imagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          _getImageUrl(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                ),
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue.shade100, Colors.blue.shade50],
                          ),
                        ),
                        child: Icon(
                          Icons.library_books,
                          size: 48,
                          color: Colors.blue.shade700,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.book, size: 12, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Stok: ${book['stock'] ?? '0'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleBorrowAction(book),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBorrowed
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isBorrowed ? 'Balikkan' : 'Pinjam',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        elevation: 0,
        title: const Text(
          'Perpus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildBooksView()
          : _currentIndex == 1
          ? const UserPeminjamanScreen()
          : _currentIndex == 2
          ? const ProfileScreen()
          : _buildBooksView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey.shade600,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Peminjaman',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
        onTap: (index) {
          if (index == 3) {
            _handleLogout();
          } else {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }
}
