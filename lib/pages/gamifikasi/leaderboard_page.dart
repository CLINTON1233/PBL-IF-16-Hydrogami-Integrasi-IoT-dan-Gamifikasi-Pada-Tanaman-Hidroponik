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

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  int _bottomNavCurrentIndex = 0;
  List<LeaderboardUser> _leaderboardData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _currentUserName = 'Loading...';
  int _currentUserCoins = 0;
  int _currentUserPoints = 0;
  String _currentUserId = '';
  int _currentUserLevel = 1;
  int _currentUserRank = 0;
  LeaderboardService? _leaderboardService;
  late AnimationController _animationController;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _avatarAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeServices();
      await _loadUserData();
      await _loadLeaderboardData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (mounted) {
        setState(() {
          _leaderboardService = LeaderboardService(
            baseUrl: 'http://10.0.2.2:8000/api',
            token: token,
          );
        });
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal menginisialisasi layanan';
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      _currentUserId = prefs.getString('current_user_id') ?? '';

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
          debugPrint('Error fetching user data: $e');
        }
      }

      if (mounted) {
        setState(() {
          _currentUserName = prefs.getString('username') ?? 'Guest';
          _currentUserCoins =
              prefs.getInt('${_currentUserId}_total_coins') ?? 0;
          _currentUserPoints =
              prefs.getInt('${_currentUserId}_current_exp') ?? 0;
          _currentUserLevel =
              prefs.getInt('${_currentUserId}_current_level') ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data pengguna';
        });
      }
    }
  }

  Future<void> _loadLeaderboardData() async {
    if (_leaderboardService == null) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final leaderboard = await _leaderboardService!.getLeaderboard();

      if (mounted) {
        setState(() {
          _leaderboardData = leaderboard;
          _isLoading = false;
          _currentUserRank = _findCurrentUserRank();
        });
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat leaderboard: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _loadLeaderboardData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    await _loadUserData();
    await _loadLeaderboardData();

    if (mounted) {
      _showCustomSnackBar(context, 'Data berhasil diperbarui', Colors.green);
    }
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  int _findCurrentUserRank() {
    if (_currentUserId.isEmpty) return 0;

    for (int i = 0; i < _leaderboardData.length; i++) {
      if (_leaderboardData[i].id.toString() == _currentUserId) {
        if (mounted) {
          setState(() {
            _currentUserPoints = _leaderboardData[i].poin;
            _currentUserLevel = _leaderboardData[i].level;
          });
        }
        return i + 1;
      }
    }
    return 0;
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
    return rank <= 3 ? Colors.black : Colors.grey[600]!;
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.emoji_events;
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.person;
    }
  }

  void _navigateToPage(int index) {
    if (!mounted) return;

    setState(() {
      _bottomNavCurrentIndex = index;
    });

    Widget page;
    switch (index) {
      case 0:
        page = const BerandaPage();
        break;
      case 1:
        page = const NotifikasiPage();
        break;
      case 2:
        page = const PanduanPage();
        break;
      case 3:
        page = const ProfilPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        title: Text(
          'Leaderboard',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF24D17E)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaderboardData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24D17E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Coba Lagi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: const Color(0xFF24D17E),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header Section
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
                              AnimatedBuilder(
                                animation: _avatarAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _avatarAnimation.value,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 40,
                                            backgroundImage: const AssetImage(
                                                'assets/profile.jpg'),
                                            onBackgroundImageError:
                                                (exception, stackTrace) {
                                              debugPrint(
                                                  'Error loading profile image: $exception');
                                            },
                                            child: const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        if (_currentUserRank > 0)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: _getRankColor(
                                                  _currentUserRank),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              '$_currentUserRank',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _getRankTextColor(
                                                    _currentUserRank),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _currentUserName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_currentUserRank > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Posisi #$_currentUserRank di Leaderboard',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      // Spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      // Leaderboard List
                      _leaderboardData.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.leaderboard_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada data leaderboard',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final user = _leaderboardData[index];
                                  final isCurrentUser =
                                      user.id.toString() == _currentUserId;
                                  return AnimatedOpacity(
                                    opacity: _isLoading ? 0.0 : 1.0,
                                    duration: Duration(
                                        milliseconds: 300 + (index * 100)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 4),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: index < 3
                                              ? LinearGradient(
                                                  colors: [
                                                    _getRankColor(index + 1)
                                                        .withOpacity(0.2),
                                                    Colors.white,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isCurrentUser
                                              ? const Color(0xFFE8F5E9)
                                              : index < 3
                                                  ? null
                                                  : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () {
                                              // Optional: Add tap feedback or user profile view
                                            },
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              leading: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      _getRankColor(index + 1),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    _getRankIcon(index + 1),
                                                    color: _getRankTextColor(
                                                        index + 1),
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user.username,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isCurrentUser)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 8.0),
                                                      child: Icon(Icons.star,
                                                          color: Colors.amber,
                                                          size: 16),
                                                    ),
                                                ],
                                              ),
                                              subtitle: Text(
                                                "${user.poin} EXP | Level ${user.level}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              trailing: Text(
                                                '#${index + 1}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      const Color(0xFF24D17E),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: _leaderboardData.length,
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
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
                  MaterialPageRoute(
                      builder: (context) => const NotifikasiPage()),
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
              activeIcon: Icon(Icons.home_rounded),
              icon: Icon(Icons.home_outlined),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.notifications_rounded),
              icon: Icon(Icons.notifications_outlined),
              label: 'Notifikasi',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.book_rounded),
              icon: Icon(Icons.book_outlined),
              label: 'Panduan',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.person_rounded),
              icon: Icon(Icons.person_outline_rounded),
              label: 'Akun',
            ),
          ],
          selectedItemColor: const Color(0xFF24D17E),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
