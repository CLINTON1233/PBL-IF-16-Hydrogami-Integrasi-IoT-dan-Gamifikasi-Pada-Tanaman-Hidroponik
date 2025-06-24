import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application_hydrogami/services/leaderboard_services.dart';
import 'package:application_hydrogami/models/leaderboard_model.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  int _bottomNavCurrentIndex = 0;
  List<LeaderboardUser> _leaderboardData = [];
  bool _isLoading = true;
  String _currentUserName = 'Loading...';
  int _currentUserCoins = 0;
  int _currentUserPoints = 0;
  String _currentUserId = '';
  int _currentUserLevel = 1;
  int _currentUserRank = 0;
  LeaderboardService? _leaderboardService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeServices();
      await _loadUserData();
      await _loadLeaderboardData();
    });
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _leaderboardService = LeaderboardService(
        baseUrl: 'http://10.0.2.2:8000/api',
        token: token,
      );
    });

    _loadLeaderboardData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Debug: Print semua key yang ada
    print('All keys in SharedPreferences: ${prefs.getKeys()}');

    // Ambil current user ID
    _currentUserId = prefs.getString('current_user_id') ?? '';
    print('Current user ID: $_currentUserId');

    // Jika tidak ada user ID, coba ambil dari API
    if (_currentUserId.isEmpty && token != null) {
      try {
        final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/user'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          _currentUserId = userData['id'].toString();
          await prefs.setString('current_user_id', _currentUserId);
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    setState(() {
      _currentUserName = prefs.getString('username') ?? 'Guest';
      _currentUserCoins = prefs.getInt('${_currentUserId}_total_coins') ??
          prefs.getInt('total_coins') ??
          0; // Fallback
      _currentUserPoints = prefs.getInt('${_currentUserId}_current_exp') ??
          prefs.getInt('current_exp') ??
          0; // Fallback
      _currentUserLevel = prefs.getInt('${_currentUserId}_current_level') ??
          prefs.getInt('current_level') ??
          1; // Fallback

      print('''
    Loaded user data:
    - Name: $_currentUserName
    - Coins: $_currentUserCoins
    - Points: $_currentUserPoints
    - Level: $_currentUserLevel
    ''');
    });
  }

  Future<void> _loadLeaderboardData() async {
    if (_leaderboardService == null) return;

    try {
      final leaderboard = await _leaderboardService!.getLeaderboard();
      setState(() {
        _leaderboardData = leaderboard;
        _isLoading = false;

        // Find current user's rank
        _currentUserRank = _findCurrentUserRank();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat leaderboard: $e')),
      );
    }
  }

  // Fungsi untuk refresh data
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadUserData();
    await _loadLeaderboardData();
    
    // Tampilkan pesan berhasil refresh
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data berhasil diperbarui'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  int _findCurrentUserRank() {
    if (_currentUserId.isEmpty) return 0;

    for (int i = 0; i < _leaderboardData.length; i++) {
      if (_leaderboardData[i].id.toString() == _currentUserId) {
        // Update user data dengan data terbaru dari leaderboard
        setState(() {
          _currentUserPoints = _leaderboardData[i].poin;
          _currentUserLevel = _leaderboardData[i].level;
        });
        return i + 1;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        centerTitle: false,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'Leaderboard',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp),
          iconSize: 20.0,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFF24D17E),
              child: CustomScrollView(
                slivers: [
                  // Header Leaderboard sebagai SliverToBoxAdapter
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF24D17E),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundImage: AssetImage('assets/profile.jpg'),
                              ),
                              if (_currentUserRank > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _getRankColor(_currentUserRank),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '$_currentUserRank',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _getRankTextColor(_currentUserRank),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentUserName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "$_currentUserPoints EXP | $_currentUserCoins Koin",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          if (_currentUserRank > 0)
                            Text(
                              "Posisi Anda #$_currentUserRank di Leaderboard",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Tab Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),
                  
                  // Leaderboard List sebagai SliverList
                  _leaderboardData.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(child: Text('Belum ada data leaderboard')),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final user = _leaderboardData[index];
                              final isCurrentUser =
                                  user.id.toString() == _currentUserId;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getRankColor(index + 1),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (index + 1).toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _getRankTextColor(index + 1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          user.username,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (isCurrentUser)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      "${user.poin} EXP",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: Text(
                                      "Level ${user.level}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF24D17E),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _leaderboardData.length,
                          ),
                        ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFFF3F3F3);
    }
  }

  Color _getRankTextColor(int rank) {
    return Colors.black;
  }

  Widget _buildTabButton(String title, {required bool isSelected}) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : const Color(0xFF24D17E),
        foregroundColor: isSelected ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildBottomNavigation() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF24D17E),
        onTap: (index) {
          setState(() {
            _bottomNavCurrentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BerandaPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotifikasiPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PanduanPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilPage()),
              );
              break;
          }
        },
        currentIndex: _bottomNavCurrentIndex,
        items: const [
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.home, color: Colors.black),
            icon: Icon(Icons.home, color: Colors.white),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.notification_add, color: Colors.black),
            icon: Icon(Icons.notification_add, color: Colors.white),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.assignment, color: Colors.black),
            icon: Icon(Icons.assignment, color: Colors.white),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.person, color: Colors.black),
            icon: Icon(Icons.person, color: Colors.white),
            label: 'Akun',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
      ),
    );
  }
}