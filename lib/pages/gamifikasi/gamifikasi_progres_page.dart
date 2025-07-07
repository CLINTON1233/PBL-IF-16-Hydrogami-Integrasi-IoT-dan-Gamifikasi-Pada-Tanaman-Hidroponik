import 'package:application_hydrogami/models/misi_model.dart';
import 'package:application_hydrogami/models/gamifikasi_model.dart';
import 'package:application_hydrogami/pages/gamifikasi/reward_page.dart';
import 'package:application_hydrogami/services/misi_service.dart';
import 'package:application_hydrogami/services/gamifikasi_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
import 'package:simple_animations/simple_animations.dart';
import 'rain_effect.dart';
import 'package:application_hydrogami/pages/gamifikasi/leaderboard_page.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';

extension WeekNumber on DateTime {
  int get weekOfYear {
    final date = DateTime(year, month, day);
    final firstDayOfYear = DateTime(year, 1, 1);
    final difference = date.difference(firstDayOfYear).inDays;
    return ((difference + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }
}

class GamifikasiProgresPage extends StatefulWidget {
  const GamifikasiProgresPage({super.key});

  @override
  State<GamifikasiProgresPage> createState() => _GamifikasiProgresPageState();
}

class _GamifikasiProgresPageState extends State<GamifikasiProgresPage>
    with TickerProviderStateMixin {
  final MisiService _misiService = MisiService();
  late GamificationService _gamificationService;
  List<Misi> _misiList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _bottomNavCurrentIndex = 0;
  bool _isDailySelected = true;

  // Progress tracking
  int _currentExp = 0;
  int _totalCoins = 0;
  int _currentLevel = 1;
  final int _expPerLevel = 200;
  final int _maxLevel = 15; // Maximum level

  // User data
  String _userId = '';
  String _userName = '';

  // Confetti controller
  late ConfettiController _confettiController;

  // Mission Tracking
  bool _hasCompletedMissionToday = false;

  // Animation controllers
  late AnimationController _progressAnimationController;
  late AnimationController _coinAnimationController;
  late AnimationController _levelUpAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _coinAnimation;
  late Animation<double> _levelUpAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _levelUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _coinAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _coinAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _levelUpAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _levelUpAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant GamifikasiProgresPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controlBounceAnimation();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _coinAnimationController.dispose();
    _levelUpAnimationController.dispose();
    _confettiController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _controlBounceAnimation() {
    if (_hasCompletedMissionToday) {
      _bounceController.repeat(reverse: true);
    } else {
      _bounceController.stop();
    }
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadMisiData();
    await _checkDailyMissions();
    _controlBounceAnimation();
  }

  // Mascot image selection based on level and completion status
  String _getMascotImage() {
    String baseImage;

    if (_hasCompletedMissionToday) {
      // Happy mascot variations
      if (_currentLevel >= 10) {
        baseImage = 'assets/maskot_happy_adult.png';
      } else if (_currentLevel >= 5) {
        baseImage = 'assets/maskot_happy_remaja.png';
      } else {
        baseImage = 'assets/maskot_happy.png';
      }
    } else {
      // Sad mascot variations
      if (_currentLevel >= 10) {
        baseImage = 'assets/maskot_sedih_adult.png';
      } else if (_currentLevel >= 5) {
        baseImage = 'assets/maskot_sedih_remaja.png';
      } else {
        baseImage = 'assets/maskot_sedih.png';
      }
    }

    return baseImage;
  }

  // Reset mascot function
  void _resetMascot() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Konsisten dengan template
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Sesuai template
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh,
                size: 80,
                color: Colors.amber, // Warna konsisten
              ),
              const SizedBox(height: 16),
              Text(
                'RESET MASKOT',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber, // Warna konsisten
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Level $_currentLevel → Level 1',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin mereset maskot?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tindakan ini akan:\n• Mereset EXP ke 0\n• Mereset Level ke 1\n• Koin tetap tersimpan\n• Maskot kembali ke bentuk awal',
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _performMascotReset();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF24D17E), // Warna hijau konsisten
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performMascotReset() async {
    try {
      setState(() {
        _currentExp = 0;
        _currentLevel = 1;
        _hasCompletedMissionToday = false;
      });

      await _saveProgressData();
      _updateProgressAnimation();
      _controlBounceAnimation();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Maskot berhasil direset! Mulai petualangan baru!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _debugUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mereset maskot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _gamificationService = GamificationService(token);

    try {
      final userResponse = await http.get(
        Uri.parse('https://admin-hydrogami.up.railway.app/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final userId = userData['id'].toString();
        final userName = userData['username'] ?? 'Pengguna Hydrogami';

        await prefs.setString('current_user_id', userId);
        await prefs.setString('current_user_name', userName);
        await prefs.setString('${userId}_username', userName);

        setState(() {
          _userId = userId;
          _userName = userName;
        });

        try {
          final gamificationData = await _gamificationService.getGamification();

          int level = gamificationData.level;
          if (level > _maxLevel) {
            level = _maxLevel;
          }

          await _updateProgress(
            gamificationData.poin,
            gamificationData.coin,
            level,
            saveToLocal: true,
          );

          print(
              'Gamification data loaded from API: EXP=${gamificationData.poin}, Coins=${gamificationData.coin}, Level=$level');
        } catch (e) {
          print('Failed to fetch gamification data from API: $e');
          await _loadProgressDataFromLocal(prefs, userId);
        }
      } else {
        throw Exception('Failed to load user data: ${userResponse.statusCode}');
      }
    } catch (e) {
      print('Error loading user data: $e');
      final savedUserId = prefs.getString('current_user_id');
      final savedUserName = prefs.getString('current_user_name');

      if (savedUserId != null && savedUserName != null) {
        setState(() {
          _userId = savedUserId;
          _userName = savedUserName;
        });
        await _loadProgressDataFromLocal(prefs, savedUserId);
      } else {
        await _setDefaultUser(prefs);
      }
    }
  }

  Future<void> _updateProgress(int exp, int coins, int level,
      {bool saveToLocal = false}) async {
    int cappedLevel = level > _maxLevel ? _maxLevel : level;

    setState(() {
      _currentExp = exp;
      _totalCoins = coins;
      _currentLevel = cappedLevel;
    });

    if (saveToLocal) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_userId}_current_exp', _currentExp);
      await prefs.setInt('${_userId}_total_coins', _totalCoins);
      await prefs.setInt('${_userId}_current_level', _currentLevel);
    }

    _updateProgressAnimation();
  }

  Future<void> _loadProgressDataFromLocal(
      SharedPreferences prefs, String userId) async {
    int level = prefs.getInt('${userId}_current_level') ?? 1;
    if (level > _maxLevel) {
      level = _maxLevel;
      await prefs.setInt('${userId}_current_level', level);
    }

    setState(() {
      _currentExp = prefs.getInt('${userId}_current_exp') ?? 0;
      _totalCoins = prefs.getInt('${userId}_total_coins') ?? 0;
      _currentLevel = level;
    });
    _updateProgressAnimation();
  }

  Future<void> _setDefaultUser(SharedPreferences prefs) async {
    final defaultId = prefs.getString('default_user_id') ??
        'default_user_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('default_user_id', defaultId);
    await prefs.setString('current_user_id', defaultId);
    await prefs.setString('${defaultId}_username', 'Pengguna Hydrogami');

    setState(() {
      _userId = defaultId;
      _userName = 'Pengguna Hydrogami';
    });

    await _loadProgressDataFromLocal(prefs, defaultId);
  }

  Future<void> _saveProgressData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_userId}_current_exp', _currentExp);
    await prefs.setInt('${_userId}_total_coins', _totalCoins);
    await prefs.setInt('${_userId}_current_level', _currentLevel);
    await _saveLeaderboardData();
    await _syncProgressWithApi();
  }

  void _debugUserData() {
    print('=== DEBUG USER DATA ===');
    print('User ID: $_userId');
    print('User Name: $_userName');
    print('Current EXP: $_currentExp');
    print('Total Coins: $_totalCoins');
    print('Current Level: $_currentLevel');
    print('Max Level: $_maxLevel');
    print('Is at Max Level: ${_currentLevel >= _maxLevel}');
    print('Mascot Image: ${_getMascotImage()}');
    print('========================');
  }

  Future<void> _syncProgressWithApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        print('No token available for API sync');
        return;
      }

      final gamificationService = GamificationService(token);
      final success = await gamificationService.updateGamification(
        _currentExp,
        _totalCoins,
        _currentLevel,
      );

      if (success) {
        print('Progress synced with API successfully');
      } else {
        await _forceSyncWithAPI();
      }
    } catch (e) {
      print('Error syncing progress with API: $e');
    }
  }

  Future<void> _forceSyncWithAPI() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Token not found');
      }

      final gamificationData = await _gamificationService.getGamification();

      int level = gamificationData.level;
      if (level > _maxLevel) {
        level = _maxLevel;
      }

      await _updateProgress(
        gamificationData.poin,
        gamificationData.coin,
        level,
        saveToLocal: true,
      );

      await _saveLeaderboardData();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil disinkronisasi dengan server'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal sinkronisasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveLeaderboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final leaderboardData = {
      'id_pengguna': _userId,
      'nama_pengguna': _userName,
      'total_poin': _currentExp,
      'dibuat_pada': DateTime.now().toIso8601String(),
      'level': _currentLevel,
      'total_coins': _totalCoins,
    };

    await prefs.setString(
        '${_userId}_leaderboard_data', json.encode(leaderboardData));
    await _saveToGlobalLeaderboard(leaderboardData);
  }

  Future<void> _saveToGlobalLeaderboard(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final existingDataString = prefs.getString('global_leaderboard') ?? '[]';
    List<dynamic> leaderboardList = json.decode(existingDataString);

    int existingIndex =
        leaderboardList.indexWhere((item) => item['id_pengguna'] == _userId);

    if (existingIndex != -1) {
      leaderboardList[existingIndex] = userData;
    } else {
      leaderboardList.add(userData);
    }

    await prefs.setString('global_leaderboard', json.encode(leaderboardList));
  }

  Future<List<String>> _getCompletedMissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_userId}_completed_missions') ?? [];
  }

  Future<void> _saveCompletedMissions(List<String> completedMissions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        '${_userId}_completed_missions', completedMissions);
  }

  void _updateProgressAnimation() {
    if (_currentLevel >= _maxLevel) {
      _progressAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ));
    } else {
      int expInCurrentLevel = _currentExp % _expPerLevel;
      double progress = expInCurrentLevel / _expPerLevel;

      _progressAnimation = Tween<double>(
        begin: 0.0,
        end: progress,
      ).animate(CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ));
    }

    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  int _getExpForCurrentLevel() {
    if (_currentLevel >= _maxLevel) {
      return _expPerLevel;
    }
    return _currentExp % _expPerLevel;
  }

  int _getExpNeededForNextLevel() {
    if (_currentLevel >= _maxLevel) {
      return 0;
    }
    return _expPerLevel - (_currentExp % _expPerLevel);
  }

  Future<void> _loadMisiData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isConnected = await _misiService.testConnection();
      if (!isConnected) {
        throw Exception(
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      }

      final misi = await _misiService.getAllMisi();
      final completedMissions = await _getCompletedMissions();

      for (var mission in misi) {
        if (completedMissions.contains(mission.namaMisi)) {
          mission.statusMisi = 'completed';
        }
      }

      setState(() {
        _misiList = _sortMissions(_filterMissionsByType(misi));
        _isLoading = false;
      });

      if (_misiList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada misi tersedia saat ini'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error in _loadMisiData: $e');

      setState(() {
        _isLoading = false;
        _errorMessage = _getUserFriendlyError(e);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: _loadMisiData,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _loadMisiData();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Text('Data berhasil diperbarui'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat data: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  String _getUserFriendlyError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Coba lagi nanti.';
    } else if (error.toString().contains('FormatException')) {
      return 'Format data tidak valid dari server.';
    }
    return 'Terjadi kesalahan. Coba lagi nanti.';
  }

  List<Misi> _filterMissionsByType(List<Misi> missions) {
    return missions.where((misi) {
      if (_isDailySelected) {
        return misi.tipeMisi == 'harian';
      } else {
        return misi.tipeMisi == 'mingguan';
      }
    }).toList();
  }

  List<Misi> _sortMissions(List<Misi> missions) {
    final incomplete =
        missions.where((m) => m.statusMisi != 'completed').toList();
    final completed =
        missions.where((m) => m.statusMisi == 'completed').toList();
    return [...incomplete, ...completed];
  }

  void _toggleMissionType(bool isDaily) {
    setState(() {
      _isDailySelected = isDaily;
    });
    _loadMisiData();
  }

  Future<void> _completeMission(Misi misi) async {
    if (misi.statusMisi == 'completed') return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (misi.tipeMisi == 'mingguan') {
      final lastWeek = prefs.getString('${_userId}_last_week_number');
      final currentWeek = _getCurrentWeekNumber();

      if (lastWeek != currentWeek) {
        await prefs.setString('${_userId}_last_week_number', currentWeek);
        await _resetWeeklyMissions();
      }
    }

    final lastMissionDate = prefs.getString('${_userId}_last_mission_date');
    final completedToday =
        prefs.getInt('${_userId}_missions_completed_today') ?? 0;

    bool isFirstMissionToday = false;

    if (lastMissionDate != today) {
      await prefs.setString('${_userId}_last_mission_date', today);
      await prefs.setInt('${_userId}_missions_completed_today', 1);
      isFirstMissionToday = true;
    } else {
      await prefs.setInt(
          '${_userId}_missions_completed_today', completedToday + 1);
      isFirstMissionToday = (completedToday == 0);
    }

    int oldLevel = _currentLevel;
    int newExp = _currentExp + misi.poin;
    int newCoins = _totalCoins + (misi.poin ~/ 2);
    int newLevel = (newExp ~/ _expPerLevel) + 1;

    if (newLevel > _maxLevel) {
      newLevel = _maxLevel;
    }

    setState(() {
      misi.statusMisi = 'completed';
      _misiList = _sortMissions(_misiList);
      _currentExp = newExp;
      _totalCoins = newCoins;
      _currentLevel = newLevel;
      _hasCompletedMissionToday = true;
    });

    _controlBounceAnimation();

    if (isFirstMissionToday) {
      _confettiController.play();
    }

    final completedMissions = await _getCompletedMissions();
    completedMissions.add(misi.namaMisi.toString());
    await _saveCompletedMissions(completedMissions);

    await _saveProgressData();
    _updateProgressAnimation();

    _coinAnimationController.reset();
    _coinAnimationController.forward().then((_) {
      _coinAnimationController.reverse();
    });

    if (newLevel > oldLevel) {
      _confettiController.play();

      if (newLevel >= _maxLevel) {
        _showMaxLevelDialog();
      } else {
        _showLevelUpDialog(oldLevel, newLevel);
      }
      _levelUpAnimationController.reset();
      _levelUpAnimationController.forward().then((_) {
        _levelUpAnimationController.reverse();
      });
    }

    String expMessage = newLevel >= _maxLevel
        ? 'Misi "${misi.namaMisi}" selesai! Level maksimal tercapai!'
        : 'Misi "${misi.namaMisi}" selesai! +${misi.poin} EXP';

// Untuk color (terpisah)
    Color messageColor = newLevel >= _maxLevel
        ? Color.fromARGB(255, 148, 115, 115)
        : Colors.green;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(expMessage)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    _debugUserData();
  }

  void _showMaxLevelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Konsisten dengan template
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Sesuai template
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.amber, // Warna konsisten
              ),
              const SizedBox(height: 16),
              Text(
                'LEVEL MAKSIMAL!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber, // Warna konsisten
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Level $_maxLevel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat! Anda telah mencapai level maksimal!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Koin Anda: $_totalCoins',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetMascot();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF24D17E), // Warna hijau konsisten
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Reset Maskot',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCurrentWeekNumber() {
    final now = DateTime.now();
    return '${now.year}-${now.weekOfYear}';
  }

  Future<void> _resetWeeklyMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final completedMissions = await _getCompletedMissions();

    final weeklyMissions =
        _misiList.where((m) => m.tipeMisi == 'mingguan').toList();
    for (var mission in weeklyMissions) {
      completedMissions.remove(mission.namaMisi);
      mission.statusMisi = 'pending';
    }

    await _saveCompletedMissions(completedMissions);
    setState(() {
      _misiList = _sortMissions(_filterMissionsByType(_misiList));
    });
  }

  Future<void> _checkDailyMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastMissionDate = prefs.getString('${_userId}_last_mission_date');
    final completedToday =
        prefs.getInt('${_userId}_missions_completed_today') ?? 0;

    setState(() {
      _hasCompletedMissionToday =
          (lastMissionDate == today && completedToday > 0);
    });
  }

  void _showLevelUpDialog(int oldLevel, int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                'LEVEL UP!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Level $oldLevel → Level $newLevel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat! Anda telah naik ke level $newLevel!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24D17E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lanjutkan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUserInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person,
                size: 80,
                color: Colors.amber, // Using amber to match template
              ),
              const SizedBox(height: 16),
              Text(
                'PROFIL PENGGUNA',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber, // Using amber to match template
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Level $_currentLevel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildUserInfoItem(
                        'Nama Pengguna', _userName, Icons.person),
                    const Divider(height: 16),
                    _buildUserInfoItem('ID Pengguna', _userId, Icons.code),
                    const Divider(height: 16),
                    _buildUserInfoItem('Total EXP', '$_currentExp', Icons.star),
                    const Divider(height: 16),
                    _buildUserInfoItem(
                        'Total Koin', '$_totalCoins', Icons.monetization_on),
                    const Divider(height: 16),
                    _buildUserInfoItem(
                        'Progress Level',
                        '${_getExpForCurrentLevel()}/$_expPerLevel EXP',
                        Icons.trending_up),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24D17E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF24D17E),
              ),
            )
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
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleRefresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24D17E),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: const Color(0xFF24D17E),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeaderSection(),
                        _buildProgressSection(),
                        _buildMissionSection(),
                        _misiList.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tidak ada misi tersedia',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 20),
                                itemCount: _misiList.length,
                                itemBuilder: (context, index) {
                                  return _missionCard(misi: _misiList[index]);
                                },
                              ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
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
            'Gamifikasi Progress',
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
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF24D17E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Widget penyeimbang (tetap ada meskipun reset button tidak muncul)
              _currentLevel >= _maxLevel
                  ? IconButton(
                      onPressed: _resetMascot,
                      icon: const Icon(Icons.refresh),
                      color: Colors.white,
                      tooltip: 'Reset Maskot',
                    )
                  : const SizedBox(
                      width: 48), // Sesuaikan lebar dengan icon button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedBuilder(
                    animation: _coinAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _coinAnimation.value,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RewardPage()),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            splashColor: Colors.amber.withOpacity(0.2),
                            highlightColor: Colors.amber.withOpacity(0.1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$_currentExp',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _coinAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _coinAnimation.value,
                        child: _buildRewardWidget(coins: _totalCoins),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: _showUserInfoDialog,
                    icon: const Icon(Icons.info),
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFF24D17E),
          child: Center(
            child: AnimatedBuilder(
              animation: _levelUpAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _levelUpAnimation.value,
                  child: Text(
                    'Level $_currentLevel',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          color: const Color(0xFF24D17E),
          width: double.infinity,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!_hasCompletedMissionToday) const RainEffect(),
              if (_hasCompletedMissionToday)
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_bounceAnimation.value),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    _getMascotImage(),
                    height: 200,
                  ),
                )
              else
                Image.asset(
                  _getMascotImage(),
                  height: 200,
                ),
              if (_hasCompletedMissionToday)
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple
                  ],
                ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFF24D17E),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: Center(
            child: Column(
              children: [
                Text(
                  '${_getExpForCurrentLevel()}/$_expPerLevel EXP',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${_getExpNeededForNextLevel()} EXP Untuk Ke Level Selanjutnya',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF24D17E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.yellow, Colors.orange],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $_currentLevel',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              Text(
                _currentLevel >= _maxLevel
                    ? 'MAX'
                    : 'Level ${_currentLevel + 1}',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Daftar Misi',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              _buildLeaderboardWidget(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggleMissionType(true),
                  borderRadius: BorderRadius.circular(30),
                  splashColor: const Color(0xFF24D17E).withOpacity(0.3),
                  highlightColor: const Color(0xFF24D17E).withOpacity(0.2),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _isDailySelected
                          ? const Color(0xFF24D17E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Harian',
                      style: TextStyle(
                        color: _isDailySelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggleMissionType(false),
                  borderRadius: BorderRadius.circular(30),
                  splashColor: const Color(0xFF24D17E).withOpacity(0.3),
                  highlightColor: const Color(0xFF24D17E).withOpacity(0.2),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isDailySelected
                          ? const Color(0xFF24D17E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Mingguan',
                      style: TextStyle(
                        color: !_isDailySelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionCard({required Misi misi}) {
    bool isCompleted = misi.statusMisi == 'completed';

    IconData getIconForStatus(String status) {
      switch (status.toLowerCase()) {
        case 'completed':
          return Icons.check_circle;
        case 'in progress':
          return Icons.hourglass_empty;
        case 'pending':
          return Icons.schedule;
        default:
          return Icons.assignment;
      }
    }

    Color getColorForStatus(String status) {
      switch (status.toLowerCase()) {
        case 'completed':
          return const Color(0xFF24D17E);
        case 'in progress':
          return Colors.blue;
        case 'pending':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    Color statusColor = getColorForStatus(misi.statusMisi);
    IconData statusIcon = getIconForStatus(misi.statusMisi);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check_circle : statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      misi.namaMisi,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isCompleted ? Colors.grey[600] : Colors.black,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      misi.deskripsiMisi,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: isCompleted ? Colors.grey : Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${misi.poin} EXP',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isCompleted
                                    ? Colors.grey[600]
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            misi.statusMisi.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: misi.tipeMisi == 'harian'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            misi.tipeMisi.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: misi.tipeMisi == 'harian'
                                  ? Colors.blue
                                  : Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (!isCompleted) {
                      _completeMission(misi);
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  splashColor: statusColor.withOpacity(0.3),
                  highlightColor: statusColor.withOpacity(0.2),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted ? statusColor : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
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

  Widget _buildBottomNavigation() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF24D17E),
        currentIndex: _bottomNavCurrentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildRewardWidget({required int coins}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RewardPage()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.amber.withOpacity(0.2),
        highlightColor: Colors.amber.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              const SizedBox(width: 5),
              Text(
                coins.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardWidget() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LeaderboardPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.leaderboard, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
