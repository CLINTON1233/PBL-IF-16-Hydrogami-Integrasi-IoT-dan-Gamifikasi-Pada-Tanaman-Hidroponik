import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:application_hydrogami/models/reward_model.dart';
import 'package:application_hydrogami/services/reward_services.dart';
import 'package:application_hydrogami/services/gamifikasi_services.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'dart:ui' as ui;

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage>
    with SingleTickerProviderStateMixin {
  // User data
  int _userCoins = 0;
  int _userExp = 0;
  int _currentLevel = 1;
  final int _expPerLevel = 200;
  String _userId = '';

  // Gacha system
  late AnimationController _controller;
  late Animation<double> _animation;
  double _angle = 0;
  double _finalAngle = 0;
  bool _isSpinning = false;
  final Random _random = Random();
  final List<String> _gachaResults = [];
  final List<String> _redeemResults = [];
  int _selectedRedeemOption = 0;

  // Services and data
  late RewardService _rewardService;
  late GamificationService _gamificationService;
  List<Reward> _gachaRewardsList = [];
  List<Reward> _redeemRewardsList = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Navigation
  int _bottomNavCurrentIndex = 0;

  // Gacha rewards with colors
  List<Map<String, dynamic>> _gachaRewards = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );

    _animation.addListener(() {
      setState(() {
        _angle = _animation.value * _finalAngle;
      });
    });

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        _calculateResult();
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _rewardService = RewardService(token);
    _gamificationService = GamificationService(token);

    try {
      setState(() {
        _userId = prefs.getString('current_user_id') ?? '';
        _userCoins = prefs.getInt('${_userId}_total_coins') ?? 0;
        _userExp = prefs.getInt('${_userId}_current_exp') ?? 0;
        _currentLevel = prefs.getInt('${_userId}_current_level') ?? 1;
      });

      // Try to get fresh data from API
      try {
        final gamificationData = await _gamificationService.getGamification();
        setState(() {
          _userCoins = gamificationData.coin;
          _userExp = gamificationData.poin;
          _currentLevel = gamificationData.level;
        });
      } catch (e) {
        print('Using local data: $e');
      }

      await _loadRewards();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user data: ${e.toString()}';
      });
    }
  }

  Future<void> _loadRewards() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final gachaRewards = await _rewardService.getGachaRewards();
      final redeemRewards = await _rewardService.getRedeemRewards();

      setState(() {
        _gachaRewardsList = gachaRewards;
        _redeemRewardsList = redeemRewards;
        _isLoading = false;

        // Transform API data to wheel format
        _gachaRewards = _gachaRewardsList
            .map((reward) => {
                  'type': reward.subtype ?? 'zonk',
                  'value': reward.amount ?? 0,
                  'probability':
                      _calculateProbability(reward.subtype, reward.amount),
                  'color': reward.color ?? '#2196F3',
                  'label': reward.label ?? 'Reward',
                })
            .toList();

        // Debug info
        print('Total rewards: ${_gachaRewards.length}');
        for (int i = 0; i < _gachaRewards.length; i++) {
          print(
              'Reward $i: ${_gachaRewards[i]['label']} - ${_gachaRewards[i]['value']}');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load rewards: ${e.toString()}';
      });
      _showCustomSnackBar(context, 'Gagal memuat rewards: $e', Colors.red);
    }
  }

  double _calculateProbability(String? subtype, int? amount) {
    if (subtype == 'zonk') return 1;
    if (amount != null) {
      if (amount <= 10) return 0.3;
      if (amount <= 20) return 0.2;
      if (amount <= 50) return 0.1;
    }
    return 0.1;
  }

  int _calculateLevel(int exp) {
    // Tambahkan 1 ketika exp mencapai kelipatan _expPerLevel
    return (exp / _expPerLevel).floor() + 1;
  }

  // ✅ FIXED: Improved level up detection
  void _checkLevelUp(int oldExp, int newExp) async {
    int oldLevel = _calculateLevel(oldExp);
    int newLevel = _calculateLevel(newExp);

    print('Checking level up - Old Level: $oldLevel, New Level: $newLevel');
    print('Old EXP: $oldExp, New EXP: $newExp');

    if (newLevel > oldLevel) {
      print('LEVEL UP DETECTED! Showing dialog...');

      // ✅ FIXED: Use WidgetsBinding to ensure dialog shows after state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLevelUpDialog(oldLevel, newLevel);
        }
      });
    }
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
                  backgroundColor: const Color.fromARGB(255, 8, 143, 78),
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

  void _calculateResult() {
    if (_gachaRewards.isEmpty) return;

    // ✅ FIXED: Improved calculation logic
    final normalizedAngle = _angle % (2 * pi);
    final sectorAngle = 2 * pi / _gachaRewards.length;

    // Since wheel starts from top (12 o'clock) and arrow points up
    // We need to calculate which sector the arrow is pointing to
    // Convert angle to sector index (clockwise from top)
    int selectedIndex = ((2 * pi - normalizedAngle) / sectorAngle).floor();

    // Ensure index is within valid range
    selectedIndex = selectedIndex % _gachaRewards.length;

    // Debug information
    print('Final angle: $_angle');
    print('Normalized angle: $normalizedAngle');
    print('Sector angle: $sectorAngle');
    print('Selected index: $selectedIndex');
    print(
        'Selected reward: ${_gachaRewards[selectedIndex]['label']} - ${_gachaRewards[selectedIndex]['value']}');

    _processReward(_gachaRewards[selectedIndex]);
  }

  void _processReward(Map<String, dynamic> reward) async {
    int oldExp = _userExp; // ✅ Store old EXP for level up check
    int newExp = _userExp;
    int newCoins = _userCoins;
    String resultMessage;

    // Get type (fallback to subtype for backward compatibility)
    String? type =
        (reward['type'] ?? reward['subtype'])?.toString().toLowerCase();
    int value = reward['value'] as int? ?? 0;

    print('Processed type: $type');
    print('Reward value: $value');

    if (type == 'zonk') {
      resultMessage = 'Zonk! Coba lagi!';
    } else if (type == 'exp') {
      newExp += value;
      resultMessage = 'Kamu dapat $value EXP!';
      print('✅ ADDING EXP: $value, New EXP: $newExp');
    } else if (type == 'coin') {
      newCoins += value;
      resultMessage = 'Kamu dapat $value koin!';
      print('✅ ADDING COINS: $value, New Coins: $newCoins');
    } else {
      // Default to coins if type is not recognized
      print('⚠️ UNKNOWN TYPE: $type, defaulting to coins');
      newCoins += value;
      resultMessage = 'You got $value coins!';
    }

    print(
        'Final values - EXP: $_userExp -> $newExp, Coins: $_userCoins -> $newCoins');

    setState(() {
      _userExp = newExp;
      _userCoins = newCoins;
      _currentLevel = _calculateLevel(newExp);
      _gachaResults.insert(0, resultMessage); // ✅ Only for gacha results
      if (_gachaResults.length > 5) {
        _gachaResults.removeLast();
      }
    });

    // ✅ FIXED: Pass old EXP for proper level up detection
    _checkLevelUp(oldExp, newExp);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_userId}_current_exp', _userExp);
    await prefs.setInt('${_userId}_total_coins', _userCoins);
    await prefs.setInt('${_userId}_current_level', _currentLevel);

    try {
      await _gamificationService.updateGamification(
          _userExp, _userCoins, _currentLevel);
    } catch (e) {
      print('Failed to update gamification: $e');
    }
  }

  void _spinWheel() {
    if (_gachaRewards.isEmpty) {
      _showCustomSnackBar(context, 'Gacha tidak tersedia', Colors.amber);
      return;
    }

    if (_userCoins < 10) {
      _showCustomSnackBar(
          context, 'Koin tidak cukup. Butuh 10 koin', Colors.red);
      return;
    }

    if (_isSpinning) return;

    // Create random rotation
    final baseRotations = 5 + _random.nextInt(5); // 5-9 full rotations
    final randomAngle = _random.nextDouble() * 2 * pi; // Random angle 0-2π
    _finalAngle = (baseRotations * 2 * pi) + randomAngle;

    setState(() {
      _isSpinning = true;
      _userCoins -= 10;
      _angle = 0; // Reset to 0
    });

    // Save coins immediately
    _saveCoinsToPrefs();

    _controller.forward(from: 0);
  }

  Future<void> _saveCoinsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_userId}_total_coins', _userCoins);
  }

  void _performRedeem() async {
    if (_redeemRewardsList.isEmpty) return;

    final selectedReward = _redeemRewardsList[_selectedRedeemOption];
    final requiredCoins = selectedReward.koinDibutuhkan ?? 0;

    if (_userCoins < requiredCoins) {
      _showCustomSnackBar(
          context, 'Koin tidak cukup. Butuh $requiredCoins koin', Colors.red);
      return;
    }

    setState(() {
      _userCoins -= requiredCoins;
      _redeemResults.insert(
        0,
        'Berhasil menukar Rp ${NumberFormat('#,###').format(selectedReward.amount)}!',
      );
      if (_redeemResults.length > 5) {
        _redeemResults.removeLast();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_userId}_total_coins', _userCoins);

    try {
      await _gamificationService.updateGamification(
          _userExp, _userCoins, _currentLevel);
    } catch (e) {
      print('Failed to update gamification: $e');
    }

    // Dialog yang diperbarui
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'PENUKARAN BERHASIL!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${NumberFormat('#,###').format(selectedReward.amount)}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Penukaran koin berhasil diproses!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 8, 143, 78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    await _loadUserData();
    await _loadRewards();

    // Show success message
    _showCustomSnackBar(context, 'Data berhasil diperbarui', Colors.green);
  }

  Widget _buildUserStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: const Color.fromARGB(255, 8, 143, 78),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Level', '$_currentLevel', Colors.white, Icons.trending_up),
          _buildStatDivider(),
          _buildStatItem(
              'Koin', '$_userCoins', Colors.white, Icons.monetization_on),
          _buildStatDivider(),
          _buildStatItem('EXP', '$_userExp', Colors.white, Icons.grade),
        ],
      ),
    );
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

  Widget _buildStatItem(
      String label, String value, Color textColor, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: textColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  // Replace your existing _buildGachaSection() and _buildRedeemSection() methods with these improved versions:

  Widget _buildGachaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 8, 143, 78).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.casino,
                  color: const Color.fromARGB(255, 8, 143, 78),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Undian',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gunakan 10 koin untuk mendapatkan reward!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:  const Color.fromARGB(255, 8, 143, 78).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:  const Color.fromARGB(255, 8, 143, 78).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color.fromARGB(255, 8, 143, 78),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_gachaRewards.length} reward tersedia untuk dimenangkan',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color.fromARGB(255, 8, 143, 78),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Wheel Container (grey background)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wheel
                Transform.rotate(
                  angle: _angle,
                  child: CustomPaint(
                    painter: _WheelPainter(rewards: _gachaRewards),
                    size: const Size(250, 250),
                  ),
                ),
                // Arrow
                CustomPaint(
                  painter: _ArrowPainter(),
                  size: const Size(40, 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Spin Button (white background)
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSpinning ? null : _spinWheel,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isSpinning ? Colors.grey[400] :  const Color.fromARGB(255, 8, 143, 78),
                foregroundColor: Colors.white,
                elevation: _isSpinning ? 0 : 2,
                shadowColor:  const Color.fromARGB(255, 8, 143, 78).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSpinning
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Memutar...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.loop, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Putar Roda',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Results Section
          if (_gachaResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green[100]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Colors.green[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Riwayat Undian',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._gachaResults.take(3).map((result) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              result.contains('Zonk')
                                  ? Icons.close_rounded
                                  : Icons.check_circle_rounded,
                              size: 16,
                              color: result.contains('Zonk')
                                  ? Colors.red[600]
                                  : Colors.green[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                result,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: result.contains('Zonk')
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRedeemSection() {
    return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 8, 143, 78).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color:  const Color.fromARGB(255, 8, 143, 78),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tukar Koin',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tukar koinmu menjadi uang tunai.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Options Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Nominal Penukaran',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reward Options
                  Column(
                    children: _redeemRewardsList.map((reward) {
                      int index = _redeemRewardsList.indexOf(reward);
                      bool isSelected = _selectedRedeemOption == index;
                      bool canAfford =
                          _userCoins >= (reward.koinDibutuhkan ?? 0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ?  const Color.fromARGB(255, 8, 143, 78).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ?  const Color.fromARGB(255, 8, 143, 78)
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: RadioListTile<int>(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          activeColor: const Color.fromARGB(255, 8, 143, 78),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                       const Color.fromARGB(255, 8, 143, 78).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Rp ${NumberFormat('#,###').format(reward.amount)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 8, 143, 78),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${reward.koinDibutuhkan} koin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: canAfford
                                        ? Colors.black87
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (!canAfford)
                                Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                            ],
                          ),
                          value: index,
                          groupValue: _selectedRedeemOption,
                          onChanged: canAfford
                              ? (value) {
                                  setState(() {
                                    _selectedRedeemOption = value!;
                                  });
                                }
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Redeem Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _redeemRewardsList.isNotEmpty &&
                        _userCoins >=
                            (_redeemRewardsList[_selectedRedeemOption]
                                    .koinDibutuhkan ??
                                0)
                    ? _performRedeem
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:  const Color.fromARGB(255, 8, 143, 78),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color.fromARGB(255, 8, 143, 78).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swap_horiz, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tukar Koin',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Redeem Results Section
            if (_redeemResults.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green[100]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Colors.green[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Riwayat Penukaran',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._redeemResults.take(3).map((result) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  result,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ));
  }

  // Bottom Navigation Widget
  Widget _buildBottomNavigation() {
    return Container(
      color: Colors.white, // tambahin ini biar latar belakangnya full putih
      child: Container(
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
                    MaterialPageRoute(
                        builder: (context) => const BerandaPage()),
                  );
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GamifikasiPage()),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PanduanPage()),
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
                activeIcon: Icon(Icons.tune_rounded),
                icon: Icon(Icons.tune_outlined),
                label: 'Kontrol',
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
            selectedItemColor: const Color.fromARGB(255, 8, 143, 78),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 8, 143, 78),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Reward',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            // Navigate to BerandaPage instead of popping
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BerandaPage()),
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: const Color.fromARGB(255, 8, 143, 78),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRewards,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:  const Color.fromARGB(255, 8, 143, 78),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                  onRefresh: _refreshData,
                  color: const Color.fromARGB(255, 8, 143, 78),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildUserStats(),
                        const SizedBox(height: 15),
                        _buildGachaSection(),
                        _buildRedeemSection(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ✅ FIXED: WheelPainter with proper sector arrangement
class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> rewards;

  _WheelPainter({required this.rewards});

  @override
  void paint(Canvas canvas, Size size) {
    if (rewards.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectorAngle = 2 * pi / rewards.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // ✅ Start from top (12 o'clock position)
    final startAngle = -pi / 2;

    for (int i = 0; i < rewards.length; i++) {
      Color color;
      try {
        color =
            Color(int.parse(rewards[i]['color']!.replaceFirst('#', '0xff')));
      } catch (e) {
        // Use different default colors for each sector
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.pink,
          Colors.indigo
        ];
        color = colors[i % colors.length];
      }

      // Draw sector
      paint.color = color;
      final currentAngle = startAngle + (i * sectorAngle);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sectorAngle,
        true,
        paint,
      );

      // Draw border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sectorAngle,
        true,
        strokePaint,
      );

      // Add text
      final textAngle = currentAngle + sectorAngle / 2;
      final textRadius = radius * 0.6;

      final textSpan = TextSpan(
        text: rewards[i]['label'] ?? 'Reward ${i + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        ),
      );

      textPainter.text = textSpan;
      textPainter.layout();

      // Calculate text position
      final textX =
          center.dx + textRadius * cos(textAngle) - textPainter.width / 2;
      final textY =
          center.dy + textRadius * sin(textAngle) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Draw center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, 20, paint);
    paint.color = Colors.black;
    strokePaint.strokeWidth = 3;
    canvas.drawCircle(center, 20, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ✅ FIXED: Arrow painter centered and pointing upward
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    final path = Path();
    // Arrow pointing upward from center
    path.moveTo(center.dx, center.dy - 15); // Top point
    path.lineTo(center.dx - 8, center.dy + 5); // Bottom left
    path.lineTo(center.dx + 8, center.dy + 5); // Bottom right
    path.close();

    canvas.drawPath(path, strokePaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
