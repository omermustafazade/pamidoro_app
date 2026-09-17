// File: screens/tabs/tasks_tab.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';
import '../../services/database_service.dart';

class TasksTab extends StatefulWidget {
  final Function(AgendaTask) onTaskPlay;

  const TasksTab({super.key, required this.onTaskPlay});

  @override
  State<TasksTab> createState() => TasksTabState(); // YENİ: Public State çağrıldı
}

// YENİ: GlobalKey ile diğer sayfalardan erişilebilmesi için sınıfın başındaki "_" kaldırıldı
class TasksTabState extends State<TasksTab> {
  final IDatabaseService _dbService = LocalDatabaseService();
  final TextEditingController _taskController = TextEditingController();

  bool _isLoading = true;
  List<AgendaTask> _tasks = [];
  List<String> _folders = ['Genel Çalışma'];
  String _selectedFolder = 'Genel Çalışma';
  String _activeFilter = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // YENİ: HomeScreen üzerinden tetiklenebilen yenileme fonksiyonu
  void refreshTasks() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tasks = await _dbService.getAgendaTasks();
    final folders = await _dbService.getAllFolders();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _folders = folders.isNotEmpty ? folders : ['Genel Çalışma'];
        if (!_folders.contains(_selectedFolder)) _selectedFolder = _folders.first;
        if (_activeFilter != 'Tümü' && !_folders.contains(_activeFilter)) {
          _activeFilter = 'Tümü';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.mediumImpact();
    final newTask = AgendaTask(
      title: title,
      folderName: _selectedFolder,
      createdAt: DateTime.now(),
      isPinned: false,
      subtasks: const [],
      orderIndex: _tasks.length,
    );

    await _dbService.addAgendaTask(newTask);
    _taskController.clear();
    FocusScope.of(context).unfocus();
    _loadData();
  }

  Future<void> _toggleTask(AgendaTask task) async {
    HapticFeedback.lightImpact();
    final updatedTask = AgendaTask(
      id: task.id,
      title: task.title,
      folderName: task.folderName,
      isCompleted: !task.isCompleted,
      isPinned: task.isPinned,
      createdAt: task.createdAt,
      subtasks: task.subtasks,
      orderIndex: task.orderIndex,
    );

    await _dbService.updateAgendaTask(updatedTask);
    _loadData();
  }

  Future<void> _togglePin(AgendaTask task) async {
    HapticFeedback.selectionClick();
    final updatedTask = AgendaTask(
      id: task.id,
      title: task.title,
      folderName: task.folderName,
      isCompleted: task.isCompleted,
      isPinned: !task.isPinned,
      createdAt: task.createdAt,
      subtasks: task.subtasks,
      orderIndex: task.orderIndex,
    );

    await _dbService.updateAgendaTask(updatedTask);
    _loadData();
  }

  void _openPremiumFolderSelector({required String initialFolder, required Function(String) onFolderSelected}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          String searchQuery = '';
          return StatefulBuilder(
              builder: (context, setModalState) {
                final filteredFolders = _folders.where((f) => f.toLowerCase().contains(searchQuery.toLowerCase())).toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                  ),
                  child: SafeArea(
                    bottom: true,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 24),
                        const Text('Proje Seç', style: TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),

                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: TextField(
                            onChanged: (val) {
                              setModalState(() => searchQuery = val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Projelerde ara...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkGreen),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 3)),
                            ),
                          ),
                        ),

                        Expanded(
                          child: filteredFolders.isEmpty
                              ? Center(child: Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)))
                              : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredFolders.length,
                            itemBuilder: (context, index) {
                              final folder = filteredFolders[index];
                              final isSelected = initialFolder == folder;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onFolderSelected(folder);
                                  Navigator.pop(context);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.yellow : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.darkGreen, width: 3),
                                    boxShadow: isSelected
                                        ? const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                                        : const [BoxShadow(color: Colors.transparent, offset: Offset(0, 0))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: isSelected ? Colors.white : AppColors.background,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: isSelected ? AppColors.darkGreen : Colors.transparent, width: 2)
                                        ),
                                        child: Icon(Icons.folder_rounded, color: isSelected ? AppColors.darkGreen : Colors.grey.shade400, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(child: Text(folder, style: TextStyle(color: isSelected ? AppColors.darkGreen : AppColors.darkBlue, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5))),
                                      if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.darkGreen, size: 28),
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
          );
        }
    );
  }

  void _showEditTaskSheet(AgendaTask task) {
    HapticFeedback.selectionClick();
    TextEditingController editController = TextEditingController(text: task.title);
    String editFolder = task.folderName;
    List<Map<String, dynamic>> tempSubtasks = List.from(task.subtasks);

    if (!_folders.contains(editFolder)) {
      editFolder = _folders.isNotEmpty ? _folders.first : 'Genel Çalışma';
    }

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                return Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset > 0 ? bottomInset + 24 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 24),
                        const Text('Görevi Düzenle', style: TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 24),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: editController,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 16),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 3)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    _openPremiumFolderSelector(
                                        initialFolder: editFolder,
                                        onFolderSelected: (newFolder) {
                                          setModalState(() => editFolder = newFolder);
                                        }
                                    );
                                  },
                                  child: Container(
                                    height: 54,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(color: AppColors.lightBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkGreen, width: 2)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(editFolder, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 14))),
                                        const Icon(Icons.folder_rounded, color: AppColors.darkGreen),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Alt Görevler (Checklist)', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900)),
                                    GestureDetector(
                                      onTap: () {
                                        TextEditingController subController = TextEditingController();
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.darkGreen, width: 4)),
                                            title: const Text('Alt Görev Ekle', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900)),
                                            content: TextField(
                                              controller: subController, autofocus: true, textCapitalization: TextCapitalization.sentences,
                                              decoration: InputDecoration(hintText: 'Yeni adım...', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900))),
                                              GestureDetector(
                                                onTap: () {
                                                  if (subController.text.trim().isNotEmpty) {
                                                    setModalState(() => tempSubtasks.add({'title': subController.text.trim(), 'isDone': false}));
                                                    HapticFeedback.lightImpact(); Navigator.pop(ctx);
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                  decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 2)),
                                                  child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkGreen, width: 2)),
                                        child: const Text('+ Ekle', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 13)),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (tempSubtasks.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, width: 2)),
                                    child: Text('Görevi küçük adımlara bölmek için alt görev ekle.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                  )
                                else
                                  ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: tempSubtasks.length,
                                      itemBuilder: (context, index) {
                                        final sub = tempSubtasks[index];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: sub['isDone'] ? Colors.grey.shade100 : Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: sub['isDone'] ? Colors.grey.shade300 : AppColors.darkGreen, width: 2),
                                          ),
                                          child: ListTile(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              setModalState(() => tempSubtasks[index]['isDone'] = !tempSubtasks[index]['isDone']);
                                            },
                                            leading: Icon(sub['isDone'] ? Icons.check_circle_rounded : Icons.circle_outlined, color: sub['isDone'] ? AppColors.darkGreen : Colors.grey.shade400),
                                            title: Text(sub['title'], style: TextStyle(color: sub['isDone'] ? Colors.grey.shade500 : AppColors.darkBlue, fontWeight: FontWeight.w800, decoration: sub['isDone'] ? TextDecoration.lineThrough : null)),
                                            trailing: GestureDetector(
                                              onTap: () => setModalState(() => tempSubtasks.removeAt(index)),
                                              child: const Icon(Icons.close_rounded, color: AppColors.red, size: 20),
                                            ),
                                          ),
                                        );
                                      }
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final newTitle = editController.text.trim();
                            if (newTitle.isNotEmpty) {
                              HapticFeedback.heavyImpact();
                              final updatedTask = AgendaTask(
                                id: task.id,
                                title: newTitle,
                                folderName: editFolder,
                                isCompleted: task.isCompleted,
                                isPinned: task.isPinned,
                                createdAt: task.createdAt,
                                subtasks: tempSubtasks,
                                orderIndex: task.orderIndex,
                              );
                              await _dbService.updateAgendaTask(updatedTask);
                              _loadData();
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkGreen, width: 3), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]),
                            child: const Center(child: Text('Değişiklikleri Kaydet', style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w900))),
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

  void _onReorder(int oldIndex, int newIndex) {
    if (_activeFilter != 'Tümü') return;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final AgendaTask item = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, item);

      for (int i = 0; i < _tasks.length; i++) {
        _tasks[i] = AgendaTask(
          id: _tasks[i].id,
          title: _tasks[i].title,
          folderName: _tasks[i].folderName,
          isCompleted: _tasks[i].isCompleted,
          isPinned: _tasks[i].isPinned,
          createdAt: _tasks[i].createdAt,
          subtasks: _tasks[i].subtasks,
          orderIndex: i,
        );
      }
    });

    _dbService.updateTaskOrders(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    List<AgendaTask> displayTasks = _activeFilter == 'Tümü'
        ? _tasks
        : _tasks.where((t) => t.folderName == _activeFilter).toList();

    int completedCount = displayTasks.where((t) => t.isCompleted).length;
    int totalCount = displayTasks.length;
    double progress = totalCount == 0 ? 0 : completedCount / totalCount;

    String dashboardTitle = 'Hadi Başlayalım!';
    String dashboardSubtitle = 'Görevleri seni bekliyor.';
    Color dashboardBgColor = Colors.white;

    if (totalCount > 0) {
      if (progress == 1.0) {
        dashboardTitle = 'Günü Fethettin! 🎉';
        dashboardSubtitle = 'Tüm görevler tamamlandı.';
        dashboardBgColor = AppColors.mintGreen;
      } else if (progress >= 0.5) {
        dashboardTitle = 'Harika Gidiyorsun 🔥';
        dashboardSubtitle = 'Görevlerin yarısından fazlası bitti.';
        dashboardBgColor = AppColors.lightBlue.withOpacity(0.3);
      } else if (progress > 0) {
        dashboardTitle = 'İyi Bir Başlangıç 🚀';
        dashboardSubtitle = 'Hız kesmeden devam et.';
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
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
                    title: Text('Ajanda', style: TextStyle(color: AppColors.darkBlue, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 2)),
                            child: const Icon(Icons.flash_on_rounded, color: AppColors.darkGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Zihnini Boşalt', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _taskController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addTask(),
                        style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Bugün neyi başarmak istiyorsun?',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 2)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 3)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _openPremiumFolderSelector(
                                    initialFolder: _selectedFolder,
                                    onFolderSelected: (newFolder) => setState(() => _selectedFolder = newFolder)
                                );
                              },
                              child: Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.darkGreen, width: 2)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(_selectedFolder, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 14))),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGreen),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _addTask,
                            child: Container(
                              height: 54, width: 64,
                              decoration: BoxDecoration(
                                  color: AppColors.yellow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.darkGreen, width: 3),
                                  boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]
                              ),
                              child: const Icon(Icons.add_rounded, color: AppColors.darkGreen, size: 30),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (!_isLoading && _tasks.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _folders.length + 1,
                    itemBuilder: (context, index) {
                      String filterName = index == 0 ? 'Tümü' : _folders[index - 1];
                      bool isSelected = _activeFilter == filterName;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _activeFilter = filterName);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.darkGreen : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.darkGreen, width: 2),
                            boxShadow: isSelected ? const [BoxShadow(color: AppColors.yellow, offset: Offset(2, 2))] : [],
                          ),
                          child: Center(
                            child: Text(
                              filterName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.darkBlue,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (!_isLoading && displayTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: dashboardBgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.darkGreen, width: 4),
                      boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dashboardTitle, style: const TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            Text('$completedCount / $totalCount', style: const TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(dashboardSubtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.darkGreen, width: 2)
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: progress == 1.0 ? AppColors.yellow : AppColors.darkGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)))
            else if (displayTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.darkGreen, width: 4),
                        boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 3)), child: const Icon(Icons.coffee_rounded, color: AppColors.darkGreen, size: 54)),
                          const SizedBox(height: 24),
                          Text(_activeFilter == 'Tümü' ? 'Ajanda Tertemiz' : 'Bu Proje Boş', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 12),
                          Text('Planlı çalışmak başarının yarısıdır.\nZihnini boşaltmak için ilk hedefini ekle.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                sliver: SliverReorderableList(
                  onReorder: _onReorder,
                  itemCount: displayTasks.length,
                  itemBuilder: (context, index) {
                    final task = displayTasks[index];
                    int subTotal = task.subtasks.length;
                    int subDone = task.subtasks.where((s) => s['isDone'] == true).length;

                    return Material(
                      key: ValueKey(task.id ?? task.hashCode.toString()),
                      color: Colors.transparent,
                      child: Dismissible(
                        key: ValueKey('dismiss_${task.id ?? task.hashCode}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          if (task.id != null) await _dbService.deleteAgendaTask(task.id!);
                          setState(() => _tasks.removeWhere((t) => t.id == task.id));
                          HapticFeedback.mediumImpact();
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.darkGreen, width: 3)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
                        ),
                        child: GestureDetector(
                          onTap: () => _showEditTaskSheet(task),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: task.isCompleted ? Colors.grey.shade100 : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: task.isCompleted ? Colors.grey.shade400 : AppColors.darkGreen, width: 3),
                              boxShadow: task.isCompleted ? [] : const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: task.isPinned && !task.isCompleted
                                        ? const Border(left: BorderSide(color: AppColors.yellow, width: 10))
                                        : null
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _toggleTask(task),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: 34, width: 34,
                                        decoration: BoxDecoration(
                                            color: task.isCompleted ? AppColors.darkGreen : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: task.isCompleted ? AppColors.darkGreen : Colors.grey.shade400, width: 2)
                                        ),
                                        child: task.isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: TextStyle(
                                                color: task.isCompleted ? Colors.grey.shade500 : AppColors.darkBlue,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.3,
                                                decoration: task.isCompleted ? TextDecoration.lineThrough : null
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: task.isCompleted ? Colors.grey.shade200 : AppColors.background,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: task.isCompleted ? Colors.transparent : Colors.grey.shade300, width: 1)
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.folder_rounded, color: task.isCompleted ? Colors.grey.shade400 : AppColors.mintGreen, size: 12),
                                                    const SizedBox(width: 4),
                                                    Container(
                                                        constraints: const BoxConstraints(maxWidth: 100),
                                                        child: Text(task.folderName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: task.isCompleted ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w800))
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (subTotal > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                      color: task.isCompleted ? Colors.grey.shade200 : AppColors.lightBlue.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: task.isCompleted ? Colors.transparent : AppColors.lightBlue.withOpacity(0.5), width: 1)
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.checklist_rounded, color: task.isCompleted ? Colors.grey.shade400 : AppColors.darkBlue, size: 12),
                                                      const SizedBox(width: 4),
                                                      Text('$subDone/$subTotal', style: TextStyle(color: task.isCompleted ? Colors.grey.shade500 : AppColors.darkBlue, fontSize: 11, fontWeight: FontWeight.w900)),
                                                    ],
                                                  ),
                                                ),
                                              if (!task.isCompleted)
                                                GestureDetector(
                                                  onTap: () => _togglePin(task),
                                                  child: Icon(task.isPinned ? Icons.star_rounded : Icons.star_outline_rounded, color: task.isPinned ? AppColors.yellow : Colors.grey.shade400, size: 20),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!task.isCompleted) ...[
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          widget.onTaskPlay(task);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: AppColors.yellow,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppColors.darkGreen, width: 2),
                                              boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(2, 2))]
                                          ),
                                          child: const Icon(Icons.play_arrow_rounded, color: AppColors.darkGreen, size: 20),
                                        ),
                                      ),
                                      if (_activeFilter == 'Tümü') ...[
                                        const SizedBox(width: 8),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Icon(Icons.drag_handle_rounded, color: Colors.grey.shade400, size: 28),
                                        ),
                                      ]
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ),
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
}