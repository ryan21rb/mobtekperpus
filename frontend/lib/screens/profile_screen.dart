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
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF1A237E), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit Profil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                  labelText: 'Nama',
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
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF1A237E)),
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
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
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
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          const Icon(Icons.lock, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Sesi login tidak ditemukan.\nSilakan login kembali.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
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
          // Header dengan info user
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, size: 56, color: Color(0xFF1A237E)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userData!['name'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _userData!['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (isAdminOrPetugas) ...[
            // Tampilan profil admin / petugas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Detail Info Card
                  Card(
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Akun',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildProfileRow('Nama Lengkap', _userData!['name'] ?? '-'),
                          const Divider(height: 24),
                          _buildProfileRow('Alamat Email', _userData!['email'] ?? '-'),
                          const Divider(height: 24),
                          _buildProfileRow('Hak Akses', role.toUpperCase()),
                          const Divider(height: 24),
                          _buildProfileRow('Status Akun', 'Aktif'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responsibilities Info Card
                  Card(
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: role == 'admin'
                              ? [const Color(0xFF1A237E).withOpacity(0.08), const Color(0xFF3F51B5).withOpacity(0.03)]
                              : [const Color(0xFF00796B).withOpacity(0.08), const Color(0xFF009688).withOpacity(0.03)],
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
                              color: role == 'admin' ? const Color(0xFF1A237E) : const Color(0xFF00796B),
                              size: 32,
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
                                      color: role == 'admin' ? const Color(0xFF1A237E) : const Color(0xFF00796B),
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
                padding: const EdgeInsets.all(16.0),
                child: _buildStatsCards(),
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Profil', 0),
                    const SizedBox(width: 8),
                    _buildTabButton('Peminjaman Aktif', 1),
                    const SizedBox(width: 8),
                    _buildTabButton('Riwayat', 2),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildTabContent(),
            ),
          ],

          const SizedBox(height: 24),

          // Edit Profile Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'EDIT PROFIL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Peminjaman',
            value: '${_statsData?['total_borrowings'] ?? 0}',
            icon: Icons.book,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Denda',
            value: 'Rp ${_statsData?['total_fines'] ?? 0}',
            icon: Icons.attach_money,
            color: Colors.orange,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
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
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileRow('Nama', _userData!['name'] ?? '-'),
            const Divider(),
            _buildProfileRow('Email', _userData!['email'] ?? '-'),
            const Divider(),
            _buildProfileRow(
              'Role',
              (_userData!['role'] ?? 'user').toString().toUpperCase(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildCurrentBorrowingsTab() {
    if (_currentBorrowings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text(
                'Tidak ada buku yang sedang dipinjam',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _currentBorrowings.map((borrowing) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const Icon(Icons.book, color: Colors.blue),
            title: Text(
              borrowing['materi_title'] ?? borrowing['title'] ?? 'Materi',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Dipinjam: ${borrowing['tanggal_peminjaman'] ?? '-'}\nJatuh Tempo: ${borrowing['due_date'] ?? '-'}',
            ),
            isThreeLine: true,
            trailing: _buildStatusBadge(borrowing['status'] ?? 'dipinjam'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab() {
    if (_borrowingHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text(
                'Belum ada riwayat peminjaman',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _borrowingHistory.map((history) {
        bool isLate = history['is_late'] ?? false;
        int fine = history['denda'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const Icon(Icons.book_outlined, color: Colors.green),
            title: Text(
              history['materi_title'] ?? history['title'] ?? 'Materi',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dikembalikan: ${history['returned_at'] ?? '-'}'),
                if (isLate) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Denda: Rp $fine',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            isThreeLine: isLate,
            trailing: _buildStatusBadge(history['status'] ?? 'dikembalikan'),
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
        color = Colors.blue;
        label = 'Dipinjam';
        break;
      case 'dikembalikan':
        color = Colors.green;
        label = 'Dikembalikan';
        break;
      case 'pending_kembali':
        color = Colors.orange;
        label = 'Menunggu';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
