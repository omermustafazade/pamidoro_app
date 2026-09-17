// File: screens/tabs/settings_tab.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../services/database_service.dart';
import '../auth_screen.dart';
import '../../main.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final IDatabaseService _dbService = LocalDatabaseService();

  // Ayar Durumları
  bool _notificationsEnabled = true;
  bool _keepScreenAwake = true;
  bool _autoStartBreaks = false;
  bool _isLoading = true;

  // Kullanıcı Profil Bilgileri
  bool _isGuest = true;
  String _userName = 'Misafir Kullanıcı';
  String _userSubtitle = 'Verilerin sadece bu cihazda tutuluyor.';
  int _selectedAvatarIndex = 0;

  // 12 Farklı Avatar Listesi
  final List<Map<String, dynamic>> _avatars = const [
    {'icon': Icons.person_rounded, 'color': AppColors.mintGreen, 'iconColor': AppColors.darkGreen},
    {'icon': Icons.directions_bike_rounded, 'color': AppColors.yellow, 'iconColor': AppColors.darkGreen},
    {'icon': Icons.cruelty_free_rounded, 'color': AppColors.lightPink, 'iconColor': AppColors.darkGreen},
    {'icon': Icons.rocket_launch_rounded, 'color': AppColors.lightBlue, 'iconColor': AppColors.darkGreen},
    {'icon': Icons.local_florist_rounded, 'color': AppColors.red, 'iconColor': Colors.white},
    {'icon': Icons.psychology_rounded, 'color': AppColors.darkBlue, 'iconColor': Colors.white},
    {'icon': Icons.sports_esports_rounded, 'color': AppColors.yellow, 'iconColor': AppColors.red},
    {'icon': Icons.coffee_rounded, 'color': AppColors.lightBlue, 'iconColor': AppColors.darkBlue},
    {'icon': Icons.palette_rounded, 'color': AppColors.lightPink, 'iconColor': AppColors.red},
    {'icon': Icons.music_note_rounded, 'color': AppColors.mintGreen, 'iconColor': AppColors.darkBlue},
    {'icon': Icons.self_improvement_rounded, 'color': AppColors.darkBlue, 'iconColor': AppColors.mintGreen},
    {'icon': Icons.pets_rounded, 'color': AppColors.red, 'iconColor': AppColors.yellow},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndProfile();
  }

  Future<void> _loadSettingsAndProfile() async {
    final hasNotif = await _dbService.getSetting('notifications', true);
    final keepAwake = await _dbService.getSetting('keepScreenAwake', true);
    final autoBreak = await _dbService.getSetting('autoStartBreaks', false);

    await _fetchUserProfile();

    if (mounted) {
      setState(() {
        _notificationsEnabled = hasNotif;
        _keepScreenAwake = keepAwake;
        _autoStartBreaks = autoBreak;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isGuest = user.isAnonymous;
    if (!_isGuest) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _userName = data['fullName'] ?? user.displayName ?? 'Odak Ustası';
          _userSubtitle = data['email'] ?? user.email ?? 'Kayıtlı Kullanıcı';
          _selectedAvatarIndex = data['avatarIndex'] ?? 0;
        } else {
          _userName = user.displayName ?? 'Odak Ustası';
          _userSubtitle = user.email ?? 'Kayıtlı Kullanıcı';
        }
      } catch (e) {
        debugPrint("Profil bilgileri çekilemedi: $e");
        _userName = user.displayName ?? 'Odak Ustası';
        _userSubtitle = user.email ?? 'Kayıtlı Kullanıcı';
      }
    }
  }

  // --- AYAR DEĞİŞTİRME METOTLARI ---

  void _toggleNotifications(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _notificationsEnabled = value);
    await _dbService.saveSetting('notifications', value);
    if (mounted) {
      _showCustomSnackBar(
        icon: value ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
        title: value ? 'Bildirimler açık' : 'Bildirimler susturuldu',
        color: value ? AppColors.mintGreen : Colors.grey.shade800,
        textColor: value ? AppColors.darkGreen : Colors.white,
      );
    }
  }

  void _toggleKeepScreenAwake(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _keepScreenAwake = value);
    await _dbService.saveSetting('keepScreenAwake', value);
    if (mounted) {
      _showCustomSnackBar(
        icon: value ? Icons.screen_lock_portrait_rounded : Icons.smartphone_rounded,
        title: value ? 'Ekran uyanık kalacak' : 'Ekran otomatik kapanacak',
        color: AppColors.lightBlue,
        textColor: AppColors.darkBlue,
      );
    }
  }

  void _toggleAutoStartBreaks(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _autoStartBreaks = value);
    await _dbService.saveSetting('autoStartBreaks', value);
    if (mounted) {
      _showCustomSnackBar(
        icon: value ? Icons.update_rounded : Icons.pause_circle_filled_rounded,
        title: value ? 'Molalar otomatik başlayacak' : 'Manuel mola sistemi aktif',
        color: AppColors.yellow,
        textColor: AppColors.darkGreen,
      );
    }
  }

  void _showCustomSnackBar({required IconData icon, required String title, required Color color, Color textColor = Colors.white}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 15))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkGreen, width: 3),
        ),
        margin: const EdgeInsets.only(bottom: 90, left: 24, right: 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- KULLANICI DÜZENLEME (İSİM & AVATAR) ---

  void _editUserName() {
    HapticFeedback.selectionClick();
    TextEditingController nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.darkGreen, width: 4)),
          title: const Text('İsmini Düzenle', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Yeni ismin...',
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 3)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800))),
            GestureDetector(
              onTap: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != _userName) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && !user.isAnonymous) {
                    await user.updateDisplayName(newName);
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fullName': newName});
                    setState(() => _userName = newName);
                  }
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.darkGreen, width: 3),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]
                ),
                child: const Text('Kaydet', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openAvatarSelector() {
    HapticFeedback.selectionClick();

    if (_isGuest) {
      _showCustomSnackBar(
          icon: Icons.lock_person_rounded,
          title: 'Avatar seçmek için kayıt olmalısın!',
          color: AppColors.red
      );
      return;
    }

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          int tempAvatarIndex = _selectedAvatarIndex;

          return StatefulBuilder(
              builder: (context, setModalState) {
                final activeAvatar = _avatars[tempAvatarIndex];

                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                  ),
                  child: SafeArea(
                    bottom: true,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Karakterini Seç', style: TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)),
                                  child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                // Büyük Canlı Önizleme
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  height: 100, width: 100,
                                  decoration: BoxDecoration(
                                    color: activeAvatar['color'],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.darkGreen, width: 4),
                                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                                  ),
                                  child: Icon(activeAvatar['icon'], color: activeAvatar['iconColor'], size: 50),
                                ),
                                const SizedBox(height: 32),

                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.darkGreen, width: 3),
                                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.center,
                                    children: List.generate(_avatars.length, (index) {
                                      final avatar = _avatars[index];
                                      final isSelected = tempAvatarIndex == index;

                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => tempAvatarIndex = index);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          height: 60, width: 60,
                                          decoration: BoxDecoration(
                                            color: avatar['color'],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: isSelected ? AppColors.darkBlue : AppColors.darkGreen.withOpacity(0.3),
                                                width: isSelected ? 4 : 2
                                            ),
                                            boxShadow: isSelected ? const [BoxShadow(color: AppColors.darkBlue, offset: Offset(2, 2))] : [],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(avatar['icon'], color: avatar['iconColor'], size: 28),
                                              if (isSelected)
                                                Positioned(
                                                  bottom: -2, right: -2,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                        color: AppColors.yellow,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: AppColors.darkBlue, width: 2)
                                                    ),
                                                    child: const Icon(Icons.check_rounded, color: AppColors.darkBlue, size: 12),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.heavyImpact();
                              Navigator.pop(context);
                              setState(() => _selectedAvatarIndex = tempAvatarIndex);

                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null && !user.isAnonymous) {
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                  'avatarIndex': tempAvatarIndex,
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                  color: AppColors.yellow,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.darkGreen, width: 4),
                                  boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                              ),
                              child: const Center(
                                child: Text('Kaydet', style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  // --- DİĞER DİALOGLAR ---

  void _clearAllData() async {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.darkGreen, width: 4)
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 28),
              SizedBox(width: 8),
              Text('Emin Misin?', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900)),
            ],
          ),
          content: const Text(
            'Tüm geçmişin, ısı haritan ve projelerin silinecek. Bu işlem geri alınamaz.',
            style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 16))
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await _dbService.clearAllData();
                _showCustomSnackBar(icon: Icons.delete_sweep_rounded, title: 'Tüm veriler temizlendi.', color: AppColors.red);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkGreen, width: 3),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]
                ),
                child: const Text('Hepsini Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutAppDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.darkGreen, width: 4),
                boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(8, 8))]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 100, width: 100,
                  decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkGreen, width: 4),
                      boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                  ),
                  child: const Center(child: Icon(Icons.timer_rounded, color: AppColors.yellow, size: 50)),
                ),
                const SizedBox(height: 24),
                const Text('PamiDoro', style: TextStyle(color: AppColors.darkBlue, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkGreen, width: 2)
                  ),
                  child: const Text('Sürüm 1.0.0', style: TextStyle(color: AppColors.darkGreen, fontSize: 12, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Daha fazla odak, daha az stres.\nVerimliliğini artırmak için sevgiyle tasarlandı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        color: AppColors.darkGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkBlue, width: 3),
                        boxShadow: const [BoxShadow(color: AppColors.darkBlue, offset: Offset(4, 4))]
                    ),
                    child: const Center(child: Text('Kapat', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    HapticFeedback.heavyImpact();
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Çıkış Yaparken Hata Oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.darkGreen));

    final currentAvatar = _avatars[_selectedAvatarIndex % _avatars.length];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverAppBar(
          expandedHeight: 70.0,
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.background.withOpacity(0.85),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.only(left: 24, bottom: 16),
                title: Text('Ayarlar', style: TextStyle(color: AppColors.darkBlue, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YENİLENMİŞ AKTİF KULLANICI PROFİL KARTI
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isGuest ? AppColors.lightBlue.withOpacity(0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _openAvatarSelector,
                        child: Stack(
                          children: [
                            Container(
                              height: 70, width: 70,
                              decoration: BoxDecoration(
                                  color: _isGuest ? Colors.white : currentAvatar['color'],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.darkGreen, width: 3)
                              ),
                              child: Icon(
                                  _isGuest ? Icons.person_outline_rounded : currentAvatar['icon'],
                                  color: _isGuest ? AppColors.darkGreen : currentAvatar['iconColor'],
                                  size: 36
                              ),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: AppColors.darkBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2)
                                ),
                                child: Icon(_isGuest ? Icons.lock_rounded : Icons.edit_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _userName,
                                    style: const TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!_isGuest) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _editUserName,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)),
                                      child: Icon(Icons.edit_rounded, color: AppColors.darkGreen.withOpacity(0.8), size: 16),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userSubtitle,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ÇALIŞMA TERCİHLERİ
                const Text('Çalışma Tercihleri', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchSettingTile(
                        icon: Icons.screen_lock_portrait_rounded,
                        color: AppColors.lightBlue,
                        title: 'Ekran Uyanık Kalsın',
                        subtitle: 'Odaklanırken ekran kapanmaz.',
                        value: _keepScreenAwake,
                        onChanged: _toggleKeepScreenAwake,
                        hasDivider: true,
                      ),
                      _buildSwitchSettingTile(
                        icon: Icons.update_rounded,
                        color: AppColors.yellow,
                        title: 'Otomatik Mola',
                        subtitle: 'Seans bitince mola direkt başlar.',
                        value: _autoStartBreaks,
                        onChanged: _toggleAutoStartBreaks,
                        hasDivider: true,
                      ),
                      _buildSwitchSettingTile(
                        icon: Icons.notifications_active_rounded,
                        color: AppColors.lightPink,
                        title: 'Bildirimler',
                        subtitle: 'Süre bitiş uyarıları ve sesler.',
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        hasDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // VERİ & UYGULAMA BİLGİSİ
                const Text('Veri & Destek', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
                  ),
                  child: Column(
                    children: [
                      _buildActionSettingTile(
                        icon: Icons.info_outline_rounded,
                        color: AppColors.mintGreen,
                        title: 'PamiDoro Hakkında',
                        hasDivider: true,
                        onTap: _showAboutAppDialog,
                      ),
                      _buildActionSettingTile(
                        icon: Icons.delete_forever_rounded,
                        color: AppColors.red,
                        title: 'Tüm Verileri Sıfırla',
                        isDestructive: true,
                        hasDivider: false,
                        onTap: _clearAllData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ÇIKIŞ YAP / HESABA GEÇ BUTONU
                GestureDetector(
                  onTap: _signOut,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: _isGuest ? AppColors.yellow : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isGuest ? AppColors.darkGreen : AppColors.red, width: 4),
                      boxShadow: [BoxShadow(color: _isGuest ? AppColors.darkGreen : AppColors.red, offset: const Offset(6, 6))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isGuest ? Icons.person_add_alt_1_rounded : Icons.logout_rounded, color: _isGuest ? AppColors.darkGreen : AppColors.red, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _isGuest ? 'Hesap Oluştur / Giriş Yap' : 'Oturumu Kapat',
                          style: TextStyle(color: _isGuest ? AppColors.darkGreen : AppColors.red, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildSwitchSettingTile({required IconData icon, required Color color, required String title, required String subtitle, required bool value, required Function(bool) onChanged, required bool hasDivider}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkGreen, width: 2)
                ),
                child: Icon(icon, color: AppColors.darkGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Switch.adaptive(value: value, activeColor: AppColors.darkGreen, onChanged: onChanged),
            ],
          ),
        ),
        if (hasDivider) Divider(height: 1, thickness: 2, color: AppColors.darkGreen.withOpacity(0.1), indent: 70, endIndent: 20),
      ],
    );
  }

  Widget _buildActionSettingTile({required IconData icon, required Color color, required String title, bool isDestructive = false, required VoidCallback onTap, required bool hasDivider}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkGreen, width: 2)
                  ),
                  child: Icon(icon, color: isDestructive ? Colors.white : AppColors.darkGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title, style: TextStyle(color: isDestructive ? AppColors.red : AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: isDestructive ? AppColors.red.withOpacity(0.5) : AppColors.darkBlue.withOpacity(0.5), size: 18),
              ],
            ),
          ),
          if (hasDivider) Divider(height: 1, thickness: 2, color: AppColors.darkGreen.withOpacity(0.1), indent: 70, endIndent: 20),
        ],
      ),
    );
  }
}