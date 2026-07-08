import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/users.dart';

class AuthService {
  // Gunakan localhost agar CORS tidak blocked (match dengan browser origin)
  static const String _baseUrl = "http://localhost:8000/api";

  // Static variable untuk store current user
  static User? _currentUser;

  // --- FUNGSI GET CURRENT USER ---
  Future<Map<String, dynamic>?> getUser() async {
    if (_currentUser != null) {
      return {
        'id': _currentUser!.id,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'role': _currentUser!.role,
        'token': _currentUser!.token,
      };
    }
    return null;
  }

  // --- FUNGSI GET TOKEN ---
  String? getToken() {
    return _currentUser?.token;
  }

  // --- FUNGSI UPDATE CURRENT USER ---
  void updateCurrentUser({required String name, required String email, String? token}) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: name,
        email: email,
        role: _currentUser!.role,
        token: token ?? _currentUser!.token,
      );
    }
  }


  // --- FUNGSI LOGIN ---
  Future<User?> login(String email, String password) async {
    try {
      print("Mencoba login ke: $_baseUrl/login");

      final response = await http
          .post(
            Uri.parse("$_baseUrl/login"),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30)); // Extend timeout ke 30 detik

      print("LOGIN RESPONSE CODE: ${response.statusCode}");
      print("LOGIN RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Gabungkan user data dengan token
        final userData = Map<String, dynamic>.from(data['user']);
        userData['token'] = data['token'];
        _currentUser = User.fromJson(userData);
        print("User berhasil login dengan token: ${_currentUser?.token}");
        return _currentUser;
      } else {
        // Jika 401 atau error lain, print pesannya
        print("Gagal Login: ${response.body}");
        return null;
      }
    } catch (e) {
      print("ERROR KONEKSI LOGIN: $e");
      return null;
    }
  }

  // --- FUNGSI REGISTER ---
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirm,
  ) async {
    try {
      print("Mencoba register ke: $_baseUrl/register");
      print("Data: name=$name, email=$email");

      final response = await http
          .post(
            Uri.parse("$_baseUrl/register"),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation':
                  confirm, // PENTING: sesuaikan dengan backend validation
            }),
          )
          .timeout(const Duration(seconds: 30)); // Extend timeout ke 30 detik

      print("REGISTER RESPONSE: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Gabungkan user data dengan token
        final userData = Map<String, dynamic>.from(data['user']);
        userData['token'] = data['token'];
        _currentUser = User.fromJson(userData);
        print("User berhasil register dengan token: ${_currentUser?.token}");
        return true;
      } else {
        print("Gagal Register: ${response.body}");
        return false;
      }
    } catch (e) {
      print("ERROR KONEKSI REGISTER: $e");
      return false;
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<bool> logout() async {
    try {
      print("Mencoba logout ke: $_baseUrl/logout");

      final response = await http
          .post(
            Uri.parse("$_baseUrl/logout"),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (_currentUser?.token != null)
                'Authorization': 'Bearer ${_currentUser!.token}',
            },
          )
          .timeout(const Duration(seconds: 10));

      print("LOGOUT RESPONSE CODE: ${response.statusCode}");
      print("LOGOUT RESPONSE BODY: ${response.body}");

      // Clear current user
      _currentUser = null;

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR KONEKSI LOGOUT: $e");
      _currentUser = null;
      return true; // Tetap return true agar bisa back to login
    }
  }
}
