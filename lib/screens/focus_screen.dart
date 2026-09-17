// File: screens/focus_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:ui';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import 'focus_widgets.dart';

class GridBackgroundPainter extends CustomPainter {
  final Color color;
  GridBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const double spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FocusScreen extends StatefulWidget {
  final String title;
  final int durationMinutes;
  final int breakDurationMinutes;
  final Color themeColor;
  final String folderName;
  final String initialTaskName;
  final String initialSoundName;
  final String initialSoundFile;
  final bool enableMindfulness;
  final AgendaTask? agendaTask; // YENİ: Ajandadan gelen ana görev objesi

  const FocusScreen({
    super.key,
    required this.title,
    required this.durationMinutes,
    required this.breakDurationMinutes,
    required this.themeColor,
    required this.folderName,
    required this.initialTaskName,
    required this.initialSoundName,
    required this.initialSoundFile,
    required this.enableMindfulness,
    this.agendaTask, // YENİ
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  late int _totalSeconds;
  late int _currentSeconds;
  bool _isBreakTime = false;
  late int _totalBreakSeconds;
  late int _currentBreakSeconds;
  bool _autoStartBreaks = false;

  int _elapsedSeconds = 0;
  int _sessionCount = 1;
  Timer? _timer;
  Timer? _prepareTimer;
  bool _isRunning = false;
  bool _isPreparing = false;
  int _prepareCountdown = 5;
  bool _show202020Overlay = false;

  late String _taskName;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _rotationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool get _isFlowtime => widget.durationMinutes == 0;

  final List<Map<String, dynamic>> _subtasks = [];
  late String _selectedAmbientSound;

  final List<Map<String, dynamic>> _ambientSounds = [
    {'name': 'Sessiz', 'icon': Icons.volume_off_rounded, 'file': ''},
    {'name': 'Yağmur', 'icon': Icons.water_drop_rounded, 'file': 'yagmur.mp3'},
    {'name': 'Kafe', 'icon': Icons.local_cafe_rounded, 'file': 'kafe.mp3'},
    {'name': 'Orman', 'icon': Icons.park_rounded, 'file': 'orman.mp3'},
    {'name': 'Ateş', 'icon': Icons.local_fire_department_rounded, 'file': 'ates.mp3'},
    {'name': 'Rüzgar', 'icon': Icons.air_rounded, 'file': 'ruzgar.mp3'},
  ];

  Color get currentColor => _isBreakTime ? AppColors.lightBlue : widget.themeColor;

  @override
  void initState() {
    super.initState();
    _taskName = widget.initialTaskName;
    _selectedAmbientSound = widget.initialSoundName;

    // YENİ: Görev veritabanından geldiyse alt görevleri çek
    if (widget.agendaTask != null) {
      _subtasks.addAll(List<Map<String, dynamic>>.from(widget.agendaTask!.subtasks));
    }

    _totalSeconds = widget.durationMinutes * 60;
    _currentSeconds = _isFlowtime ? 0 : _totalSeconds;
    _totalBreakSeconds = widget.breakDurationMinutes * 60;
    _currentBreakSeconds = _totalBreakSeconds;

    _breathingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine));
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

    _audioPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    ));

    _applyUserSystemSettings();
  }

  Future<void> _applyUserSystemSettings() async {
    final db = LocalDatabaseService();
    bool keepAwake = await db.getSetting('keepScreenAwake', true);
    _autoStartBreaks = await db.getSetting('autoStartBreaks', false);
    if (keepAwake) WakelockPlus.enable();
  }

  // YENİ: Alt görevlerde yapılan değişiklikleri veritabanına anında yansıtır
  Future<void> _syncSubtasksToDB() async {
    if (widget.agendaTask != null && widget.agendaTask!.id != null) {
      final db = LocalDatabaseService();
      final updatedTask = AgendaTask(
        id: widget.agendaTask!.id,
        title: widget.agendaTask!.title,
        folderName: widget.agendaTask!.folderName,
        isCompleted: widget.agendaTask!.isCompleted,
        isPinned: widget.agendaTask!.isPinned,
        createdAt: widget.agendaTask!.createdAt,
        subtasks: _subtasks, // Ekrandaki güncel liste
        orderIndex: widget.agendaTask!.orderIndex,
      );
      await db.updateAgendaTask(updatedTask);
    }
  }

  void _showInAppNotification(String title, String message, Color bgColor) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_active_rounded, color: AppColors.darkGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(message, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.darkGreen, width: 4)
        ),
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.75, left: 24, right: 24),
        elevation: 0,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _onStartPressed() {
    if (_isRunning || _isPreparing) {
      _pauseTimer();
      return;
    }
    if (_isBreakTime || _elapsedSeconds > 0 || _currentSeconds < _totalSeconds) {
      _startActualTimer();
      return;
    }
    if (widget.enableMindfulness) {
      _startFocusSequence();
    } else {
      _startActualTimer();
    }
  }

  void _openSoundMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSoundSelectionSheet(),
    ).then((selectedSound) {
      if (selectedSound != null) {
        _changeAmbientSound(selectedSound['name'], selectedSound['file']);
      }
    });
  }

  Future<void> _changeAmbientSound(String soundName, String fileName) async {
    setState(() => _selectedAmbientSound = soundName);
    if (fileName.isEmpty) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      if (_isRunning && !_isBreakTime) {
        await _audioPlayer.play(AssetSource('sounds/$fileName'));
      }
    }
  }

  Widget _buildSoundSelectionSheet() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: AppColors.darkGreen, width: 4),
          boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(0, -8))]
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 60, height: 8, decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            const Text('Atmosferini Değiştir', style: TextStyle(color: AppColors.darkGreen, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
            const SizedBox(height: 8),
            const Text('Arka planda ne çalmasını istersin?', style: TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
              children: _ambientSounds.map((sound) {
                bool isSelected = _selectedAmbientSound == sound['name'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, sound);
                  },
                  child: Container(
                    width: 105, padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                        color: isSelected ? currentColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.darkGreen, width: 3),
                        boxShadow: isSelected ? const [BoxShadow(color: AppColors.darkGreen, offset: Offset(2, 2))] : const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                    ),
                    child: Column(
                      children: [
                        Icon(sound['icon'], color: AppColors.darkGreen, size: 36),
                        const SizedBox(height: 12),
                        Text(sound['name'], style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 15)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _startFocusSequence() {
    setState(() { _isPreparing = true; _prepareCountdown = 5; });
    HapticFeedback.mediumImpact();
    _prepareTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepareCountdown > 1) {
        setState(() => _prepareCountdown--);
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
        setState(() => _isPreparing = false);
        HapticFeedback.heavyImpact();
        _startActualTimer();
      }
    });
  }

  void _resumeAmbientSound() {
    final currentSound = _ambientSounds.firstWhere((s) => s['name'] == _selectedAmbientSound);
    if (currentSound['file'] != '') {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.play(AssetSource('sounds/${currentSound['file']}'));
    }
  }

  void _startActualTimer() {
    setState(() => _isRunning = true);
    if (!_isBreakTime) {
      _breathingController.repeat(reverse: true);
      _resumeAmbientSound();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isBreakTime) {
          if (_currentBreakSeconds > 0) {
            _currentBreakSeconds--;
          } else {
            _finishBreakPhase();
          }
        } else {
          _elapsedSeconds++;
          if (_isFlowtime) {
            _currentSeconds++;
          } else {
            if (_currentSeconds > 0) {
              _currentSeconds--;
            } else {
              _finishFocusPhase();
            }
          }
          if (_elapsedSeconds > 0 && _elapsedSeconds % 1200 == 0) _trigger202020Alert();
        }
      });
    });
  }

  void _skipPhase() {
    HapticFeedback.mediumImpact();
    _pauseTimer();
    setState(() {
      if (!_isBreakTime) {
        _isBreakTime = true;
        _currentBreakSeconds = _totalBreakSeconds;
      } else {
        _isBreakTime = false;
        if (_currentSeconds == 0 && !_isFlowtime) {
          _currentSeconds = _totalSeconds;
          _sessionCount++;
        }
      }
    });
  }

  void _finishFocusPhase() async {
    _pauseTimer();
    final db = LocalDatabaseService();
    if (await db.getSetting('notifications', true)) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      await NotificationService().showNotification(
        title: 'Odak Süresi Bitti! 🎯',
        body: 'Harika iş çıkardın. Şimdi ${_formatTime(_totalBreakSeconds)} dakikalık mola vakti.',
      );
      _showInAppNotification('Odak Tamamlandı', 'Şimdi dinlenme vakti.', AppColors.mintGreen);
    }
    setState(() {
      _isBreakTime = true;
      _currentBreakSeconds = _totalBreakSeconds;
    });
    if (_autoStartBreaks) _startActualTimer();
  }

  void _finishBreakPhase() async {
    _pauseTimer();
    final db = LocalDatabaseService();
    if (await db.getSetting('notifications', true)) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      await NotificationService().showNotification(
        title: 'Mola Bitti! ☕',
        body: 'Yeniden odaklanma zamanı. Haydi başlayalım!',
      );
      _showInAppNotification('Mola Bitti! ☕', 'Yeni bir seansa hazırsın.', AppColors.yellow);
    }
    setState(() {
      _isBreakTime = false;
      if (_currentSeconds == 0 && !_isFlowtime) {
        _currentSeconds = _totalSeconds;
        _sessionCount++;
      }
    });
    if (_autoStartBreaks) _startActualTimer();
  }

  void _trigger202020Alert() {
    HapticFeedback.heavyImpact();
    setState(() => _show202020Overlay = true);
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) setState(() => _show202020Overlay = false);
    });
  }

  void _pauseTimer() {
    _prepareTimer?.cancel();
    _timer?.cancel();
    _audioPlayer.pause();
    _breathingController.stop();
    setState(() { _isRunning = false; _isPreparing = false; });
  }

  Future<void> _finishSession() async {
    _pauseTimer();
    await _audioPlayer.stop();
    final db = LocalDatabaseService();
    final int elapsedMinutes = _elapsedSeconds ~/ 60;
    if (elapsedMinutes > 0) {
      await db.saveSession(FocusSession(
          date: DateTime.now(),
          durationMinutes: elapsedMinutes,
          technique: widget.title,
          folderName: widget.folderName,
          taskName: _taskName
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  void _showExitDialog() {
    _pauseTimer();
    HapticFeedback.mediumImpact();
    final int elapsedMinutes = _elapsedSeconds ~/ 60;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 32),
              const Text('Erken Ayrılıyorsun!', style: TextStyle(color: AppColors.darkBlue, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 12),
              Text(elapsedMinutes > 0 ? 'Şu ana kadar $elapsedMinutes dakika odaklandın. Kaydedelim mi?' : 'Kaydedilecek bir süre yok.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 40),
              if (elapsedMinutes > 0)
                GestureDetector(
                  onTap: () { Navigator.pop(context); _finishSession(); },
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.darkBlue, width: 3), boxShadow: const [BoxShadow(color: AppColors.darkBlue, offset: Offset(4, 4))]),
                    child: const Center(child: Text('Kaydet ve Çık', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
                  ),
                ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () { Navigator.pop(context); Navigator.pop(this.context); },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.red, width: 3), boxShadow: const [BoxShadow(color: AppColors.red, offset: Offset(4, 4))]),
                  child: const Center(child: Text('Çöpe At ve Çık', style: TextStyle(color: AppColors.red, fontSize: 20, fontWeight: FontWeight.w900))),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) { if (mounted && (_elapsedSeconds > 0 || _isBreakTime)) _startActualTimer(); });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double get _growthFactor => _isBreakTime ? 1.0 : (_isFlowtime ? (_elapsedSeconds / 3600).clamp(0.0, 1.0) : (1.0 - (_totalSeconds == 0 ? 0 : (_currentSeconds / _totalSeconds))).clamp(0.0, 1.0));

  @override
  void dispose() {
    WakelockPlus.disable();
    _audioPlayer.dispose();
    _timer?.cancel();
    _prepareTimer?.cancel();
    _breathingController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, onPopInvokedWithResult: (didPop, result) { if (!didPop) _showExitDialog(); },
      child: Scaffold(
        backgroundColor: currentColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GridBackgroundPainter(color: AppColors.darkGreen.withOpacity(0.15)),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(48), topRight: Radius.circular(48)),
                          border: const Border(top: BorderSide(color: AppColors.darkGreen, width: 4), left: BorderSide(color: AppColors.darkGreen, width: 4), right: BorderSide(color: AppColors.darkGreen, width: 4)),
                          boxShadow: [BoxShadow(color: AppColors.darkGreen.withOpacity(0.5), blurRadius: 0, offset: const Offset(0, -8))]
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 48, bottom: 24),
                              child: Column(
                                children: [
                                  TimerCircleDisplay(
                                    isRunning: _isRunning && !_isBreakTime,
                                    progress: _isBreakTime
                                        ? (1.0 - (_totalBreakSeconds == 0 ? 0 : (_currentBreakSeconds / _totalBreakSeconds)))
                                        : (_isFlowtime ? 1.0 : (_currentSeconds / _totalSeconds)),
                                    formattedTime: _isBreakTime ? _formatTime(_currentBreakSeconds) : _formatTime(_currentSeconds),
                                    isFlowtime: _isFlowtime && !_isBreakTime,
                                    themeColor: currentColor,
                                    growthFactor: _growthFactor,
                                    breathingAnimation: _breathingAnimation,
                                    rotationAnimation: _rotationController,
                                    sessionCount: _sessionCount,
                                  ),
                                  const SizedBox(height: 56),
                                  PremiumSubtaskSection(
                                    subtasks: _subtasks,
                                    themeColor: currentColor,
                                    onAddPressed: () {
                                      TextEditingController subtaskController = TextEditingController();
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.darkGreen, width: 4)),
                                          title: const Text('Alt Görev Ekle', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900, fontSize: 22)),
                                          content: TextField(
                                              controller: subtaskController, autofocus: true,
                                              decoration: InputDecoration(
                                                  hintText: 'Ufak bir adım...',
                                                  filled: true, fillColor: AppColors.background,
                                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: currentColor, width: 3)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 2))
                                              )
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 16))),
                                            GestureDetector(
                                              onTap: () {
                                                if (subtaskController.text.trim().isNotEmpty) {
                                                  setState(() => _subtasks.add({'title': subtaskController.text.trim(), 'isDone': false}));
                                                  _syncSubtasksToDB(); // YENİ: Anında veritabanına kaydet
                                                  HapticFeedback.lightImpact(); Navigator.pop(context);
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                decoration: BoxDecoration(color: currentColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 3), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]),
                                                child: const Text('Ekle', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 16)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onToggle: (index) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _subtasks[index]['isDone'] = !_subtasks[index]['isDone']);
                                      _syncSubtasksToDB(); // YENİ: Durumu DB'ye kaydet
                                    },
                                    onDelete: (index) {
                                      setState(() => _subtasks.removeAt(index));
                                      _syncSubtasksToDB(); // YENİ: Silinme işlemini kaydet
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SafeArea(top: false, child: Padding(padding: const EdgeInsets.only(bottom: 16, top: 12), child: _buildControls())),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            EyeRestOverlay(isVisible: _show202020Overlay),
            MindfulnessOverlay(isPreparing: _isPreparing, countdown: _prepareCountdown, onCancel: _pauseTimer, primaryColor: currentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.darkGreen, width: 4),
          boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
              onTap: _showExitDialog,
              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2)), child: const Icon(Icons.close_rounded, color: Colors.white, size: 22))
          ),
          Expanded(
            child: Column(
              children: [
                Text(_isBreakTime ? 'MOLA VAKTİ' : widget.title.toUpperCase(), style: const TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(_taskName, style: TextStyle(color: AppColors.darkGreen.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openSoundMenu,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: currentColor, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2)),
              child: Icon(_selectedAmbientSound == 'Sessiz' ? Icons.headphones_rounded : Icons.graphic_eq_rounded, color: AppColors.darkGreen, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isRunning && (_elapsedSeconds > 0 || _isBreakTime))
          GestureDetector(
            onTap: _showExitDialog,
            child: Container(
                margin: const EdgeInsets.only(right: 16),
                height: 64, width: 64,
                decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkGreen, width: 3),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                ),
                child: const Icon(Icons.stop_rounded, color: Colors.white, size: 32)
            ),
          ),
        GestureDetector(
          onTap: _onStartPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
                color: _isRunning ? Colors.white : currentColor,
                border: Border.all(color: AppColors.darkGreen, width: 4),
                borderRadius: BorderRadius.circular(40),
                boxShadow: _isRunning ? const [BoxShadow(color: AppColors.darkGreen, offset: Offset(2, 2))] : const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))]
            ),
            child: Text(
                _isRunning ? 'Duraklat' : 'Başla',
                style: const TextStyle(color: AppColors.darkGreen, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)
            ),
          ),
        ),
        if (_totalBreakSeconds > 0)
          GestureDetector(
            onTap: _skipPhase,
            child: Container(
                margin: const EdgeInsets.only(left: 16),
                height: 64, width: 64,
                decoration: BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkGreen, width: 3),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                ),
                child: Icon(_isBreakTime ? Icons.keyboard_double_arrow_right_rounded : Icons.coffee_rounded, color: AppColors.darkGreen, size: 32)
            ),
          ),
      ],
    );
  }
}