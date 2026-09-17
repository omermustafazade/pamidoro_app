// File: screens/tabs/widgets/focus_setup_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import '../../../utils/app_colors.dart';
import '../../../services/database_service.dart';

class FocusSetupSheet extends StatefulWidget {
  final List<String> folders;
  final List<AgendaTask> initialTasks; // YENİ: Artık String listesi değil, AgendaTask listesi alıyor

  const FocusSetupSheet({
    super.key,
    required this.folders,
    required this.initialTasks,
  });

  @override
  State<FocusSetupSheet> createState() => _FocusSetupSheetState();
}

class _FocusSetupSheetState extends State<FocusSetupSheet> {
  final IDatabaseService _dbService = LocalDatabaseService();
  final PageController _pageController = PageController();
  final TextEditingController _taskController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _currentStep = 0;
  late String _selectedFolder;

  // YENİ: Görev seçim mantığı
  List<AgendaTask> _existingTasks = [];
  AgendaTask? _selectedTask;
  bool _isAddingTask = false;

  String _selectedSoundName = 'Sessiz';
  String _selectedSoundFile = '';
  bool _isPlayingPreview = false;
  bool _isMindfulnessEnabled = true;

  final List<Map<String, dynamic>> _ambientSounds = [
    {'name': 'Sessiz', 'icon': Icons.volume_off_rounded, 'file': '', 'color': AppColors.background},
    {'name': 'Yağmur', 'icon': Icons.water_drop_rounded, 'file': 'yagmur.mp3', 'color': AppColors.lightBlue},
    {'name': 'Kafe', 'icon': Icons.local_cafe_rounded, 'file': 'kafe.mp3', 'color': AppColors.yellow},
    {'name': 'Orman', 'icon': Icons.park_rounded, 'file': 'orman.mp3', 'color': AppColors.mintGreen},
    {'name': 'Ateş', 'icon': Icons.local_fire_department_rounded, 'file': 'ates.mp3', 'color': AppColors.red},
    {'name': 'Rüzgar', 'icon': Icons.air_rounded, 'file': 'ruzgar.mp3', 'color': AppColors.lightPink},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.folders.isNotEmpty ? widget.folders.first : 'Genel Çalışma';
    _existingTasks = widget.initialTasks;
    if (_existingTasks.isNotEmpty) {
      _selectedTask = _existingTasks.first;
    }

    _audioPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _taskController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // YENİ: Seçilen klasöre göre veritabanından güncel görevleri çeker
  Future<void> _fetchTasksForFolder(String folder) async {
    List<AgendaTask> allTasks = await _dbService.getAgendaTasks();
    List<AgendaTask> folderTasks = allTasks.where((t) => t.folderName == folder && !t.isCompleted).toList();

    setState(() {
      _existingTasks = folderTasks;
      // Eğer mevcut seçili görev yeni klasörde yoksa, listedeki ilk görevi seç
      if (!folderTasks.any((t) => t.id == _selectedTask?.id)) {
        _selectedTask = folderTasks.isNotEmpty ? folderTasks.first : null;
      }
    });
  }

  // YENİ: Anında yeni görev oluşturup veritabanına kaydeder ve seçer
  Future<void> _addNewTask() async {
    if (_isAddingTask) return;
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isAddingTask = true);
    HapticFeedback.mediumImpact();

    final newTask = AgendaTask(
      title: title,
      folderName: _selectedFolder,
      createdAt: DateTime.now(),
      isPinned: false,
      subtasks: const [],
      orderIndex: 0,
    );

    await _dbService.addAgendaTask(newTask);
    _taskController.clear();
    FocusScope.of(context).unfocus();

    // Veritabanından tekrar çek ki Firestore ID'si ile gelsin
    await _fetchTasksForFolder(_selectedFolder);

    // Yeni eklenen görevi seçili hale getir
    if (_existingTasks.isNotEmpty) {
      setState(() {
        _selectedTask = _existingTasks.firstWhere((t) => t.title == title, orElse: () => _existingTasks.first);
      });
    }

    setState(() => _isAddingTask = false);
  }

  void _nextStep() {
    if (_currentStep < 2) {
      FocusScope.of(context).unfocus();
      HapticFeedback.lightImpact();
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuad,
      );
    } else {
      _finishSetup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      HapticFeedback.lightImpact();
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuad,
      );
    }
  }

  Future<void> _finishSetup() async {
    HapticFeedback.heavyImpact();
    _audioPlayer.stop();

    AgendaTask? finalTask = _selectedTask;

    // Eğer kullanıcı input alanına yazı yazdıysa ama '+' butonuna basmadan Devam dediyse
    // Kullanıcının niyetini anlayıp o görevi otomatik oluşturuyoruz.
    if (_taskController.text.trim().isNotEmpty) {
      await _addNewTask();
      finalTask = _selectedTask;
    }

    // Eğer klasörde hiç görev yoksa ve kullanıcı da eklemediyse, varsayılan bir görev oluştur
    if (finalTask == null) {
      final defaultTask = AgendaTask(
        title: "Odaklanma Seansı",
        folderName: _selectedFolder,
        createdAt: DateTime.now(),
        subtasks: const [],
      );
      await _dbService.addAgendaTask(defaultTask);
      await _fetchTasksForFolder(_selectedFolder);
      finalTask = _existingTasks.isNotEmpty ? _existingTasks.last : defaultTask;
    }

    if (mounted) {
      Navigator.pop(context, {
        'folder': _selectedFolder,
        'task': finalTask, // YENİ: Geriye metin değil tam AgendaTask objesi dönüyor
        'soundName': _selectedSoundName,
        'soundFile': _selectedSoundFile,
        'mindfulness': _isMindfulnessEnabled,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildFolderSelectionPage(),
                _buildTaskInputPage(),
                _buildSoundSelectionPage(),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, math.max(16, MediaQuery.of(context).padding.bottom + (bottomInset > 0 ? 0 : 16))),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.darkGreen.withOpacity(0.1), width: 2)),
            ),
            child: GestureDetector(
              onTap: _nextStep,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 64,
                decoration: BoxDecoration(
                  color: _currentStep == 2 ? AppColors.darkGreen : AppColors.yellow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkGreen, width: 4),
                  boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                ),
                child: Center(
                  child: Text(
                    _currentStep == 2 ? 'Seansı Başlat' : 'Devam Et',
                    style: TextStyle(
                      color: _currentStep == 2 ? Colors.white : AppColors.darkGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (bottomInset > 0) SizedBox(height: bottomInset),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                opacity: _currentStep > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2)),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen, size: 20),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Odaklanma Planı',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: AppColors.red, width: 2)),
                  child: const Icon(Icons.close_rounded, color: AppColors.red, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? AppColors.darkGreen : AppColors.background,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: index <= _currentStep ? AppColors.darkGreen : Colors.grey.shade300, width: 1),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFolderSelectionPage() {
    return _PageLayout(
      title: 'Hangi projede çalışacaksın?',
      subtitle: 'Odaklanacağın ana kategoriyi seç.',
      icon: Icons.folder_copy_rounded,
      child: widget.folders.isEmpty
          ? const Center(child: Text('Henüz bir proje yok.', style: TextStyle(color: Colors.grey)))
          : GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: widget.folders.length,
        itemBuilder: (context, index) {
          final folder = widget.folders[index];
          final isSelected = _selectedFolder == folder;

          return GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              setState(() => _selectedFolder = folder);
              await _fetchTasksForFolder(folder);
              Future.delayed(const Duration(milliseconds: 250), _nextStep);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkGreen : AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? AppColors.darkGreen : Colors.grey.shade300, width: 3),
                boxShadow: isSelected ? const [BoxShadow(color: AppColors.lightBlue, offset: Offset(4, 4))] : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: isSelected ? AppColors.mintGreen : Colors.grey.shade400,
                    size: 32,
                  ),
                  Text(
                    folder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.2,
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

  Widget _buildTaskInputPage() {
    return _PageLayout(
      title: 'Görevini belirle',
      subtitle: 'Bugün tam olarak neyi bitirmek istiyorsun?',
      icon: Icons.flag_rounded,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ekleme ve Arama Alanı
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addNewTask(),
                    style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Yeni görev ekle...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 3)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addNewTask,
                  child: Container(
                    height: 54, width: 54,
                    decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkGreen, width: 3),
                        boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(2, 2))]
                    ),
                    child: _isAddingTask
                        ? const Padding(padding: EdgeInsets.all(14.0), child: CircularProgressIndicator(color: AppColors.darkGreen, strokeWidth: 3))
                        : const Icon(Icons.add_rounded, color: AppColors.darkGreen, size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.fact_check_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                const Text('Bekleyen Görevler', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),

            // Mevcut Görevler Listesi (Seçim Alanı)
            Expanded(
              child: _existingTasks.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note_rounded, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Bu proje için bekleyen görev yok.\nYukarıdan yeni bir tane ekleyebilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _existingTasks.length,
                itemBuilder: (context, index) {
                  final t = _existingTasks[index];
                  final isSelected = _selectedTask?.id == t.id;
                  int subTotal = t.subtasks.length;
                  int subDone = t.subtasks.where((s) => s['isDone'] == true).length;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedTask = t);
                      FocusScope.of(context).unfocus();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.lightBlue.withOpacity(0.2) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.darkGreen : Colors.grey.shade300, width: 2),
                        boxShadow: isSelected ? const [BoxShadow(color: AppColors.darkGreen, offset: Offset(2, 2))] : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isSelected ? AppColors.darkGreen : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    t.title,
                                    style: TextStyle(color: isSelected ? AppColors.darkGreen : AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w800)
                                ),
                                if (subTotal > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                      '$subDone/$subTotal alt görev',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w700)
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelectionPage() {
    return _PageLayout(
      title: 'Atmosferini seç',
      subtitle: 'Arka planda ne çalmasını istersin?',
      icon: Icons.headphones_rounded,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _ambientSounds.length,
              itemBuilder: (context, index) {
                final sound = _ambientSounds[index];
                final isSelected = _selectedSoundName == sound['name'];
                Color baseColor = sound['color'];
                bool isLight = (baseColor == AppColors.yellow || baseColor == AppColors.lightPink || baseColor == AppColors.mintGreen || baseColor == AppColors.lightBlue || baseColor == AppColors.background);

                Color contentColor = isSelected ? (isLight ? AppColors.darkGreen : Colors.white) : Colors.grey.shade400;

                return GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSoundName = sound['name'];
                      _selectedSoundFile = sound['file'];
                      _isPlayingPreview = sound['file'] != '';
                    });

                    if (sound['file'] != '') {
                      await _audioPlayer.stop();
                      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
                      await _audioPlayer.play(AssetSource('sounds/${sound['file']}'));
                    } else {
                      await _audioPlayer.stop();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? baseColor : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isSelected ? AppColors.darkGreen : Colors.grey.shade300, width: 3),
                      boxShadow: isSelected ? const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(sound['icon'], color: contentColor, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          sound['name'],
                          style: TextStyle(color: isSelected ? contentColor : Colors.grey.shade500, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        if (isSelected && _isPlayingPreview) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.graphic_eq_rounded, color: contentColor.withOpacity(0.7), size: 12),
                              const SizedBox(width: 4),
                              Text('Dinleniyor', style: TextStyle(color: contentColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w800)),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isMindfulnessEnabled ? AppColors.darkGreen : Colors.grey.shade300, width: 3),
              boxShadow: _isMindfulnessEnabled ? const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))] : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _isMindfulnessEnabled ? AppColors.mintGreen : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isMindfulnessEnabled ? AppColors.darkGreen : Colors.transparent, width: 2)
                  ),
                  child: Icon(Icons.air_rounded, color: _isMindfulnessEnabled ? AppColors.darkGreen : Colors.grey.shade500, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zihinsel Isınma', style: TextStyle(color: _isMindfulnessEnabled ? AppColors.darkBlue : Colors.grey.shade700, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Seans öncesi 5 sn nefes', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isMindfulnessEnabled,
                  activeColor: AppColors.darkGreen,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() => _isMindfulnessEnabled = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _PageLayout({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mintGreen, width: 2),
                ),
                child: Icon(icon, color: AppColors.darkGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: child),
      ],
    );
  }
}