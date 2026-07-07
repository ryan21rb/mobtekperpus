import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Sesuaikan dengan folder kamu
import 'screens/petugas_screen.dart'; // <- 1. PASTIKAN IMPORT INI ADA!
import 'screens/materi_screen.dart';
import 'screens/user_screen.dart';
import 'screens/user_peminjaman_screen.dart';
import 'screens/petugas_return_queue_screen.dart';
import 'screens/petugas_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/petugas_extension_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perpus',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Rute awal aplikasi
      routes: {
        // HAPUS kata 'const' di dua baris di bawah ini:
        '/login': (context) => LoginScreen(),
        '/user': (context) => UserScreen(),
        '/petugas': (context) => PetugasScreen(),
        '/admin': (context) => MateriScreen(),
        '/user-peminjaman': (context) => const UserPeminjamanScreen(),
        '/petugas-return-queue': (context) => const PetugasReturnQueueScreen(),
        '/petugas-extension-requests': (context) => const PetugasExtensionRequestsScreen(),
        '/petugas-history': (context) => const PetugasHistoryScreen(),
        '/profile': (context) =>
            ProfileScreen(), // <- Ganti jadi ProfileScreen() di sini
      },
    );
  }
}
