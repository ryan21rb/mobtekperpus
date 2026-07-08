import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<dynamic> _activities = [];
  List<dynamic> _filteredActivities = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getUser();
      if (user != null) {
        final token = user['token'] ?? '';
        final data = await _apiService.getSystemActivities(token);
        setState(() {
          _activities = data;
          _filteredActivities = data;
          _isLoading = false;
        });
        _filterActivities(_searchController.text);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterActivities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredActivities = _activities;
      } else {
        _filteredActivities = _activities.where((act) {
          final name = (act['user_name'] ?? '').toString().toLowerCase();
          final role = (act['user_role'] ?? '').toString().toLowerCase();
          final type = (act['activity_type'] ?? '').toString().toLowerCase();
          final details = (act['details'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || role.contains(q) || type.contains(q) || details.contains(q);
        }).toList();
      }
    });
  }

  Map<String, List<dynamic>> _groupActivitiesByDate() {
    final Map<String, List<dynamic>> groups = {};
    
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    for (var act in _filteredActivities) {
      String datePart = 'Lainnya';
      final String createdAt = act['created_at'] ?? '';
      if (createdAt.isNotEmpty) {
        try {
          // Parse UTC timestamp dari API ke Local Timezone Device User
          final localDateTime = DateTime.parse(createdAt).toLocal();
          final rawDate = "${localDateTime.year}-${localDateTime.month.toString().padLeft(2, '0')}-${localDateTime.day.toString().padLeft(2, '0')}";
          
          if (rawDate == todayStr) {
            datePart = 'Hari Ini';
          } else if (rawDate == yesterdayStr) {
            datePart = 'Kemarin';
          } else {
            datePart = rawDate;
          }
        } catch (e) {
          // Fallback jika terjadi error parsing
          final rawDate = createdAt.contains('T') 
              ? createdAt.split('T')[0] 
              : createdAt.split(' ')[0];
          if (rawDate == todayStr) {
            datePart = 'Hari Ini';
          } else if (rawDate == yesterdayStr) {
            datePart = 'Kemarin';
          } else {
            datePart = rawDate;
          }
        }
      }
      
      if (!groups.containsKey(datePart)) {
        groups[datePart] = [];
      }
      groups[datePart]!.add(act);
    }
    
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groupedActivities = _groupActivitiesByDate();

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadActivities,
            color: const Color(0xFF4F46E5),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Log Aktivitas Sistem",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                        onPressed: _loadActivities,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterActivities,
                      decoration: InputDecoration(
                        hintText: "Cari berdasarkan nama, role, atau aktivitas...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4F46E5)),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterActivities('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _filteredActivities.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80.0),
                            child: Column(
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  "Belum ada log aktivitas.",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: groupedActivities.keys.map((dateKey) {
                            final items = groupedActivities[dateKey]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4F46E5).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.12)),
                                        ),
                                        child: Text(
                                          dateKey,
                                          style: const TextStyle(
                                            color: Color(0xFF4F46E5),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Divider(color: Colors.grey.shade200, thickness: 1),
                                      ),
                                    ],
                                  ),
                                ),
                                ...items.map((act) {
                                  final type = (act['activity_type'] ?? 'LOGIN').toString().toUpperCase();
                                  final isLogin = type == 'LOGIN';
                                  final color = isLogin ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                                  final icon = isLogin ? Icons.login_rounded : Icons.logout_rounded;
                                  
                                  String timeStr = '';
                                  try {
                                    // Tampilkan waktu local sesuai timezone user
                                    final localDateTime = DateTime.parse(act['created_at'] ?? '').toLocal();
                                    final hour = localDateTime.hour.toString().padLeft(2, '0');
                                    final minute = localDateTime.minute.toString().padLeft(2, '0');
                                    final second = localDateTime.second.toString().padLeft(2, '0');
                                    timeStr = "$hour:$minute:$second";
                                  } catch (e) {
                                    timeStr = act['created_at'] ?? '';
                                    if (timeStr.contains('T')) {
                                      final parts = timeStr.split('T');
                                      timeStr = parts[1].split('.')[0];
                                    } else if (timeStr.contains(' ')) {
                                      final parts = timeStr.split(' ');
                                      timeStr = parts[1];
                                    }
                                  }

                                  final role = (act['user_role'] ?? 'user').toString().toUpperCase();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
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
                                              color: color,
                                              width: 5,
                                            ),
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: color, size: 20),
                                          ),
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                act['user_name'] ?? 'Guest',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              _buildRoleBadge(role),
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  act['details'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF475569),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      timeStr,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey.shade400,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    switch (role.toLowerCase()) {
      case 'admin':
        badgeColor = const Color(0xFFFBBF24);
        break;
      case 'petugas':
        badgeColor = const Color(0xFF4F46E5);
        break;
      default:
        badgeColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
