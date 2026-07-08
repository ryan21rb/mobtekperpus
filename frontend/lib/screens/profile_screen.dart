import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/custom_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _statsData;
  List<dynamic> _currentBorrowings = [];
  List<dynamic> _borrowingHistory = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = await _authService.getUser();

      if (!mounted) return;

      if (user != null) {
        final token = user['token'] ?? '';
        final role = (user['role'] ?? 'user').toString().toLowerCase();

        Map<String, dynamic>? stats;
        List<dynamic> currentBorrowings = [];
        List<dynamic> history = [];

        if (role == 'user') {
          try {
            final statsRes = await _apiService.getUserStats(token);
            if (statsRes['success'] ?? false) {
              stats = statsRes['data'];
            }
          } catch (e) {
            print("Error loading user stats: $e");
          }

          try {
            currentBorrowings = await _apiService.getCurrentBorrowings(token);
          } catch (e) {
            print("Error loading current borrowings: $e");
          }

          try {
            history = await _apiService.getBorrowingHistory(token);
          } catch (e) {
            print("Error loading borrowing history: $e");
          }
        }

        if (!mounted) return;
        setState(() {
          _userData = user;
          _statsData = stats;
          _currentBorrowings = currentBorrowings;
          _borrowingHistory = history;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      print("Error loading profile: $e");
    }
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(
          text: _userData?['name'] ?? '',
        );
        final TextEditingController emailController = TextEditingController(
          text: _userData?['email'] ?? '',
        );

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit Profil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Alamat Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4F46E5)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
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
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final token = _userData?['token'] ?? '';
                if (token.isEmpty) return;

                Navigator.pop(context);
                setState(() => _isLoading = true);

                final result = await _apiService.updateUserProfile(
                  token: token,
                  profileData: {
                    'name': nameController.text,
                    'email': emailController.text,
                  },
                );

                if (result['success'] == true) {
                  final newToken = result['token'];
                  _authService.updateCurrentUser(
                    name: nameController.text,
                    email: emailController.text,
                    token: newToken,
                  );
                  await _loadProfileData();

                  if (mounted) {
                    CustomToast.show(
                      context,
                      newToken != null
                          ? 'Profil berhasil diperbarui. Token login baru telah diterbitkan.'
                          : 'Profil berhasil diperbarui.',
                      isSuccess: true,
                    );
                  }
                } else {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    CustomToast.show(
                      context,
                      result['message'] ?? 'Gagal memperbarui profil',
                      isError: true,
                    );
                  }
                }
              },
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : _userData == null
          ? _buildNotLoginView()
          : _buildProfileView(),
    );
  }

  Widget _buildNotLoginView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Sesi login tidak ditemukan.\nSilakan login kembali.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final role = (_userData!['role'] ?? 'user').toString().toLowerCase();
    final isAdminOrPetugas = role == 'admin' || role == 'petugas';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant Header Profile Card
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF1E1B4B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      (_userData?['name'] ?? 'U').toString().isNotEmpty
                          ? _userData!['name'][0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _userData!['name'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _userData!['email'] ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (isAdminOrPetugas) ...[
            // Tampilan profil admin / petugas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Detail Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildProfileRow('Nama Lengkap', _userData!['name'] ?? '-'),
                        const Divider(height: 24, thickness: 0.5),
                        _buildProfileRow('Alamat Email', _userData!['email'] ?? '-'),
                        const Divider(height: 24, thickness: 0.5),
                        _buildProfileRow('Hak Akses', role.toUpperCase()),
                        const Divider(height: 24, thickness: 0.5),
                        _buildProfileRow('Status Akun', 'Aktif'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Responsibilities Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: role == 'admin'
                              ? [const Color(0xFF4F46E5).withOpacity(0.06), const Color(0xFF4F46E5).withOpacity(0.01)]
                              : [const Color(0xFF10B981).withOpacity(0.06), const Color(0xFF10B981).withOpacity(0.01)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              role == 'admin' ? Icons.security_rounded : Icons.admin_panel_settings_rounded,
                              color: role == 'admin' ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                              size: 30,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role == 'admin' ? 'Tanggung Jawab Administrator' : 'Tanggung Jawab Petugas',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: role == 'admin' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    role == 'admin'
                                        ? 'Sebagai Administrator, Anda bertanggung jawab penuh atas manajemen sistem Perpus, termasuk pengelolaan data pustaka (CRUD materi/buku), pengaturan denda, kategori pustaka, serta otorisasi hak akses petugas.'
                                        : 'Sebagai Petugas Perpustakaan, Anda bertanggung jawab atas pelayanan sirkulasi Perpus. Ini mencakup pemeriksaan antrian pengembalian buku, pengesahan request perpanjangan, serta verifikasi denda pengguna.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Tampilan profil user biasa (peminjam)
            if (_statsData != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: _buildStatsCards(),
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Profil', 0),
                    const SizedBox(width: 10),
                    _buildTabButton('Peminjaman Aktif', 1),
                    const SizedBox(width: 10),
                    _buildTabButton('Riwayat Peminjaman', 2),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildTabContent(),
            ),
          ],

          const SizedBox(height: 32),

          // Edit Profile Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'EDIT PROFIL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Peminjaman',
            value: '${_statsData?['total_borrowings'] ?? 0} Buku',
            icon: Icons.bookmark_added_outlined,
            color: const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Total Denda',
            value: 'Rp ${_statsData?['total_fines']?.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.') ?? '0'}',
            icon: Icons.monetization_on_outlined,
            color: Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildCurrentBorrowingsTab();
      case 2:
        return _buildHistoryTab();
      default:
        return _buildProfileTab();
    }
  }

  Widget _buildProfileTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildProfileRow('Nama', _userData!['name'] ?? '-'),
          const Divider(height: 24, thickness: 0.5),
          _buildProfileRow('Email', _userData!['email'] ?? '-'),
          const Divider(height: 24, thickness: 0.5),
          _buildProfileRow(
            'Role Akses',
            (_userData!['role'] ?? 'user').toString().toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildCurrentBorrowingsTab() {
    if (_currentBorrowings.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada buku yang sedang dipinjam',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _currentBorrowings.map((borrowing) {
        final status = borrowing['status'] ?? 'dipinjam';
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                    width: 5,
                  ),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF4F46E5), size: 24),
                title: Text(
                  borrowing['materi_title'] ?? borrowing['title'] ?? 'Materi',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                      children: [
                        const TextSpan(text: 'Dipinjam: '),
                        TextSpan(text: borrowing['tanggal_peminjaman'] ?? '-', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                        const TextSpan(text: '\nJatuh Tempo: '),
                        TextSpan(text: borrowing['due_date'] ?? '-', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                isThreeLine: true,
                trailing: _buildStatusBadge(status),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab() {
    if (_borrowingHistory.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'Belum ada riwayat peminjaman',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _borrowingHistory.map((history) {
        bool isLate = history['is_late'] ?? false;
        int fine = history['denda'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                    color: Color(0xFF10B981),
                    width: 5,
                  ),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF10B981), size: 24),
                title: Text(
                  history['materi_title'] ?? history['title'] ?? 'Materi',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dikembalikan: ${history['returned_at'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (isLate) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Denda Terbayar: Rp $fine',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                isThreeLine: isLate,
                trailing: _buildStatusBadge(history['status'] ?? 'dikembalikan'),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'dipinjam':
        color = const Color(0xFF4F46E5);
        label = 'Dipinjam';
        break;
      case 'dikembalikan':
        color = const Color(0xFF10B981);
        label = 'Kembali';
        break;
      case 'pending_kembali':
        color = const Color(0xFFF59E0B);
        label = 'Menunggu';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
