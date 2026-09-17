// File: screens/tabs/focus_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';
import '../../services/database_service.dart';
import '../focus_screen.dart';
import '../auth_screen.dart';
import 'widgets/focus_setup_sheet.dart';

class FocusTab extends StatefulWidget {
  final VoidCallback onProfileTapped;
  final AgendaTask? preselectedTask;
  final VoidCallback? onClearPreselectedTask;

  const FocusTab({super.key, required this.onProfileTapped, this.preselectedTask, this.onClearPreselectedTask});

  @override
  State<FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends State<FocusTab> {
  final IDatabaseService _dbService = LocalDatabaseService();
  int _selectedTechniqueIndex = 0;
  int _todayTotalMinutes = 0;
  List<FocusSession> _recentSessions = [];
  bool _isLoading = true;
  int _dailyGoalMinutes = 240;

  final List<Map<String, dynamic>> _techniques = [
    {
      'title': 'Pamidor',
      'time': '25 dk Odak / 5 dk Mola',
      'focus': 25,
      'break': 5,
      'color': AppColors.red,
      'icon': Icons.timer_rounded,
      'badge': 'Popüler',
      'desc': 'Geleneksel Pomodoro tekniği. 25 dakika kesintisiz odaklanma ve ardından 5 dakika kısa mola. Sıkılmadan çalışmak için idealdir.'
    },
    {
      'title': 'Flowtime',
      'time': 'Süresiz Akış',
      'focus': 0,
      'break': 0,
      'color': AppColors.lightBlue,
      'icon': Icons.waves_rounded,
      'badge': 'Derin Odak',
      'desc': 'Kendi akışını bul. Belirli bir süre kısıtlaması olmadan, odağın bozulana kadar çalışıp daha sonra manuel mola verirsin.'
    },
    {
      'title': 'Uzun Pamidor',
      'time': '50 dk Odak / 10 dk Mola',
      'focus': 50,
      'break': 10,
      'color': AppColors.mintGreen,
      'icon': Icons.hourglass_full_rounded,
      'badge': 'Dengeli',
      'desc': 'Daha uzun süre odaklanabilenler için 50 dakika çalışma ve 10 dakika mola döngüsü.'
    },
    {
      'title': '90/30 Dengesi',
      'time': '90 dk Odak / 30 dk Mola',
      'focus': 90,
      'break': 30,
      'color': AppColors.darkGreen,
      'icon': Icons.battery_charging_full_rounded,
      'badge': 'Bilişsel',
      'desc': 'İnsan beyninin ultradiyen ritmine dayanan, 90 dakika derin odaklanma ve 30 dakika uzun mola döngüsü.'
    },
    {
      'title': '52/17',
      'time': '52 dk Odak / 17 dk Mola',
      'focus': 52,
      'break': 17,
      'color': AppColors.yellow,
      'icon': Icons.psychology_rounded,
      'badge': 'Bilimsel',
      'desc': 'Bilişsel araştırmalara dayanan modern teknik. İnsan beyni 52 dakika boyunca zirve odaklanma yaşar.'
    },
    {
      'title': 'Mikro Adım',
      'time': '10 dk Odak / 2 dk Mola',
      'focus': 10,
      'break': 2,
      'color': AppColors.lightPink,
      'icon': Icons.rocket_launch_rounded,
      'badge': 'Hızlı Başlangıç',
      'desc': 'Ertelenen zor görevlere başlamak için 10 dakika kuralı. Başladıktan sonra gerisi gelir!'
    },
    {
      'title': 'Animedoro',
      'time': '40 dk Odak / 20 dk Mola',
      'focus': 40,
      'break': 20,
      'color': AppColors.darkBlue,
      'icon': Icons.movie_filter_rounded,
      'badge': 'Eğlenceli',
      'desc': '40-60 dakika arası çalış, ödül olarak 20 dakikalık bir bölüm izle.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFocusData();
  }

  Future<void> _loadFocusData() async {
    setState(() => _isLoading = true);
    final todaySessions = await _dbService.getTodaySessions();
    final goal = await _dbService.getDailyGoal();
    int total = 0;
    for (var s in todaySessions) total += s.durationMinutes;

    if (mounted) {
      setState(() {
        _dailyGoalMinutes = goal;
        _todayTotalMinutes = total;
        _recentSessions = todaySessions.reversed.toList();
        _isLoading = false;
      });
    }
  }

  void _showRegistrationWall() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 32),
              Container(
                height: 80, width: 80,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkGreen, width: 4),
                  boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                ),
                child: const Icon(Icons.lock_person_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Deneme Süren Bitti!', style: TextStyle(color: AppColors.darkBlue, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 12),
              const Text(
                'İlk 5 seanslık ücretsiz deneme sınırına ulaştın. Uygulamayı kullanmaya devam etmek ve verilerini korumak için artık kayıt olman ZORUNLUDUR.\n\nÜstelik şu ana kadarki istatistiklerin yeni hesabına eksiksiz aktarılacak!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w700, height: 1.5),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
                  ),
                  child: const Center(
                    child: Text('Hemen Kayıt Ol', style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Şimdilik Kapat', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startFocusFlow() async {
    HapticFeedback.mediumImpact();

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      final stats = await _dbService.getFolderStats();
      int totalSessions = stats.values.fold(0, (sum, count) => sum + count);
      if (totalSessions >= 5) {
        _showRegistrationWall();
        return;
      }
    }

    final activeTechnique = _techniques[_selectedTechniqueIndex];

    // Ajandadan gelen aktif bir görev (preselectedTask) varsa
    if (widget.preselectedTask != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FocusScreen(
            title: activeTechnique['title'],
            durationMinutes: activeTechnique['focus'],
            breakDurationMinutes: activeTechnique['break'],
            themeColor: activeTechnique['color'],
            folderName: widget.preselectedTask!.folderName,
            initialTaskName: widget.preselectedTask!.title,
            initialSoundName: 'Sessiz',
            initialSoundFile: '',
            enableMindfulness: true,
            agendaTask: widget.preselectedTask,
          ),
        ),
      ).then((_) {
        _loadFocusData();
        if (widget.onClearPreselectedTask != null) widget.onClearPreselectedTask!();
      });
      return;
    }

    // Normal Akış (FocusSetupSheet üzerinden)
    List<String> folders = await _dbService.getAllFolders();
    if (folders.isEmpty) folders = ['Genel Çalışma'];

    // YENİ: Artık sadece string isimleri değil, AgendaTask objelerinin tamamını alıp gönderiyoruz
    List<AgendaTask> allTasks = await _dbService.getAgendaTasks();
    List<AgendaTask> pendingTasks = allTasks.where((t) => t.folderName == folders.first && !t.isCompleted).toList();

    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FocusSetupSheet(
        folders: folders,
        initialTasks: pendingTasks,
      ),
    );

    if (result == null || !mounted) return;

    AgendaTask activeTask = result['task'];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusScreen(
          title: activeTechnique['title'],
          durationMinutes: activeTechnique['focus'],
          breakDurationMinutes: activeTechnique['break'],
          themeColor: activeTechnique['color'],
          folderName: result['folder'],
          initialTaskName: activeTask.title,
          initialSoundName: result['soundName'],
          initialSoundFile: result['soundFile'],
          enableMindfulness: result['mindfulness'],
          agendaTask: activeTask, // YENİ: Setup ekranından dönen AgendaTask objesini gönderiyoruz
        ),
      ),
    ).then((_) => _loadFocusData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.darkGreen));

    return RefreshIndicator(
      onRefresh: _loadFocusData,
      color: AppColors.darkGreen,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderSection(onProfileTapped: widget.onProfileTapped),
            const SizedBox(height: 24),

            if (widget.preselectedTask != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.darkGreen, width: 4),
                  boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                ),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2)), child: const Icon(Icons.push_pin_rounded, color: AppColors.darkGreen, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seçili Görev', style: TextStyle(color: AppColors.darkGreen, fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(widget.preselectedTask!.title, style: const TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); if (widget.onClearPreselectedTask != null) widget.onClearPreselectedTask!(); },
                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: AppColors.darkGreen, size: 20)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text('Çalışma Modunu Seç', style: TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _buildTechniqueSelector(),
            const SizedBox(height: 20),

            _buildStickyStartButton(),
            const SizedBox(height: 32),

            const Text('İlerleme', style: TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _buildPremiumDashboard(),
            const SizedBox(height: 32),

            if (_recentSessions.isNotEmpty) ...[
              const Text('Bugünün Özeti', style: TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Kayıtları silmek için sağdan sola kaydırın', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _buildRecentSessions(),
            ] else ...[
              _buildPremiumEmptyState(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumDashboard() {
    double progress = _dailyGoalMinutes > 0 ? _todayTotalMinutes / _dailyGoalMinutes : 0.0;
    if (progress > 1.0) progress = 1.0;
    int remainingMins = _dailyGoalMinutes - _todayTotalMinutes;
    if (remainingMins < 0) remainingMins = 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.darkGreen, width: 4),
        boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Transform.rotate(
                      angle: -math.pi / 2,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        color: AppColors.yellow,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(progress >= 1.0 ? Icons.emoji_events_rounded : Icons.local_fire_department_rounded, color: AppColors.yellow, size: 24),
                    const SizedBox(height: 2),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hedef Durumu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    GestureDetector(
                      onTap: _showEditGoalDialog,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$_todayTotalMinutes / $_dailyGoalMinutes dk', style: const TextStyle(color: AppColors.mintGreen, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: progress >= 1.0 ? AppColors.yellow : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    progress >= 1.0 ? 'Hedefe Ulaştın!' : '$remainingMins dk kaldı',
                    style: TextStyle(color: progress >= 1.0 ? AppColors.darkGreen : Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.darkGreen, width: 4),
        boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 100, width: 100,
                decoration: BoxDecoration(color: AppColors.lightBlue.withOpacity(0.3), shape: BoxShape.circle),
              ),
              const Icon(Icons.auto_awesome_rounded, color: AppColors.darkBlue, size: 50),
            ],
          ),
          const SizedBox(height: 24),
          const Text('İlk Adımı At', style: TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Text(
            'Büyük başarılar küçük adımlarla başlar. Kendine uygun bir teknik seç ve hemen odaklanmaya başla.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueSelector() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _techniques.length,
        itemBuilder: (context, index) {
          final technique = _techniques[index];
          final isSelected = _selectedTechniqueIndex == index;
          Color cardColor = isSelected ? technique['color'] : Colors.white;

          bool isLightColor = technique['color'] == AppColors.yellow ||
              technique['color'] == AppColors.lightPink ||
              technique['color'] == AppColors.mintGreen ||
              technique['color'] == AppColors.lightBlue;

          Color textColor = isSelected
              ? (isLightColor ? AppColors.darkGreen : Colors.white)
              : AppColors.darkBlue;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedTechniqueIndex = index);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16, bottom: 12),
              width: 175,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.darkGreen, width: isSelected ? 4 : 2),
                boxShadow: isSelected ? const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))] : [],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -24, bottom: -24,
                    child: Icon(technique['icon'], size: 140, color: isSelected ? Colors.white.withOpacity(0.1) : technique['color'].withOpacity(0.05)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withOpacity(0.2) : technique['color'].withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16)
                              ),
                              child: Icon(technique['icon'], color: isSelected ? textColor : technique['color'], size: 32),
                            ),
                            GestureDetector(
                              onTap: () => _showTechniqueInfo(technique),
                              child: Icon(Icons.info_outline_rounded, color: isSelected ? textColor.withOpacity(0.8) : Colors.grey.shade400, size: 28),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            technique['badge'],
                            style: TextStyle(color: isSelected ? textColor : Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                        const Spacer(),
                        Text(
                            technique['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                        ),
                        const SizedBox(height: 4),
                        Text(technique['time'], style: TextStyle(color: isSelected ? textColor.withOpacity(0.9) : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTechniqueInfo(Map<String, dynamic> technique) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: technique['color'],
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkGreen, width: 4),
                      boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                  ),
                  child: Icon(technique['icon'], color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                Text('${technique['title']} Tekniği', style: const TextStyle(color: AppColors.darkBlue, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Text(technique['desc'], textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 16, height: 1.6, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditGoalDialog() {
    TextEditingController goalController = TextEditingController(text: _dailyGoalMinutes.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.darkGreen, width: 4)),
          title: const Text('Günlük Hedef', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900, fontSize: 22)),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              suffixText: 'Dakika',
              hintText: 'Örn: 120',
              filled: true,
              fillColor: AppColors.background,
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 3)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800))),
            GestureDetector(
              onTap: () async {
                int? parsedMins = int.tryParse(goalController.text.trim());
                if (parsedMins != null && parsedMins > 0) {
                  await _dbService.setDailyGoal(parsedMins);
                  _loadFocusData();
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

  Widget _buildRecentSessions() {
    return Column(
      children: _recentSessions.map((s) {
        return Dismissible(
          key: ValueKey(s.hashCode),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            await _dbService.deleteSession(s);
            _loadFocusData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kayıt silindi', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.red),
            );
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkGreen, width: 3),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkGreen, width: 3),
              boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Container(
                decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.mintGreen, width: 8))),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.mintGreen.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: AppColors.darkGreen, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.taskName, style: const TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(s.folderName, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkGreen, width: 2)),
                        child: Text('${s.durationMinutes} dk', style: const TextStyle(color: AppColors.darkGreen, fontSize: 15, fontWeight: FontWeight.w900))
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStickyStartButton() {
    final activeTechnique = _techniques[_selectedTechniqueIndex];

    bool isLightColor = activeTechnique['color'] == AppColors.yellow ||
        activeTechnique['color'] == AppColors.lightPink ||
        activeTechnique['color'] == AppColors.mintGreen ||
        activeTechnique['color'] == AppColors.lightBlue;

    Color startTextColor = isLightColor ? AppColors.darkGreen : Colors.white;
    Color playIconColor = isLightColor ? AppColors.darkGreen : AppColors.yellow;

    return GestureDetector(
      onTap: _startFocusFlow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 72,
        decoration: BoxDecoration(
          color: activeTechnique['color'],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.darkGreen, width: 4),
          boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: playIconColor,
              size: 40,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.preselectedTask != null ? 'Görevi Başlat' : '${activeTechnique['title']} Başlat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: startTextColor,
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onProfileTapped;
  const _HeaderSection({required this.onProfileTapped});

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

  String _getGreetingText() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi Geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6) return Icons.nights_stay_rounded;
    if (hour < 12) return Icons.wb_twilight_rounded;
    if (hour < 18) return Icons.wb_sunny_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null || user.isAnonymous;

    if (isGuest) {
      return _buildHeaderUI('Misafir', 0, true);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String firstName = user.displayName?.split(' ')[0] ?? 'Odak';
        int avatarIdx = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = data['fullName'] as String?;
          if (fullName != null && fullName.isNotEmpty) {
            firstName = fullName.split(' ')[0];
          }
          avatarIdx = data['avatarIndex'] ?? 0;
        }

        return _buildHeaderUI(firstName, avatarIdx, false);
      },
    );
  }

  Widget _buildHeaderUI(String firstName, int avatarIndex, bool isGuest) {
    final currentAvatar = _avatars[avatarIndex % _avatars.length];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkGreen, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getGreetingIcon(), color: AppColors.darkGreen, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${_getGreetingText()}, $firstName',
                        style: const TextStyle(color: AppColors.darkBlue, fontSize: 13, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Hedeflerine\nOdaklan.',
                  style: TextStyle(color: AppColors.darkGreen, fontSize: 32, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1.0)
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onProfileTapped,
          child: Container(
            height: 70, width: 70,
            decoration: BoxDecoration(
                color: isGuest ? Colors.white : currentAvatar['color'],
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkGreen, width: 4),
                boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(5, 5))]
            ),
            child: Icon(
                isGuest ? Icons.person_outline_rounded : currentAvatar['icon'],
                color: isGuest ? AppColors.darkGreen : currentAvatar['iconColor'],
                size: 38
            ),
          ),
        ),
      ],
    );
  }
}