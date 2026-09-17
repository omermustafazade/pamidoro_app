// File: screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../services/database_service.dart';

// Eklendi
import 'tabs/focus_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  AgendaTask? _activeAgendaTask;

  // YENİ: TasksTab sekmesinin durumuna dışarıdan ulaşmak ve tetiklemek için GlobalKey
  final GlobalKey<TasksTabState> _tasksTabKey = GlobalKey<TasksTabState>();

  void _handleTaskPlay(AgendaTask task) {
    setState(() {
      _activeAgendaTask = task;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: [
                FocusTab(
                  onProfileTapped: () => setState(() => _currentIndex = 3),
                  preselectedTask: _activeAgendaTask,
                  onClearPreselectedTask: () => setState(() => _activeAgendaTask = null),
                ),
                TasksTab(
                    key: _tasksTabKey, // YENİ: Oluşturduğumuz anahtarı widget'a bağlıyoruz
                    onTaskPlay: _handleTaskPlay
                ),
                const AnalyticsTab(),
                const SettingsTab(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: AppColors.darkGreen, width: 4),
                boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(icon: Icons.timer_rounded, label: 'Odak', index: 0),
                  _buildNavItem(icon: Icons.task_alt_rounded, label: 'Görevler', index: 1),
                  _buildNavItem(icon: Icons.bar_chart_rounded, label: 'Kayıtlar', index: 2),
                  _buildNavItem(icon: Icons.settings_rounded, label: 'Ayarlar', index: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);

        // YENİ: Görevler sekmesine geçildiğinde, o sayfanın verilerini veritabanından tazeleyerek senkronize et
        if (index == 1) {
          _tasksTabKey.currentState?.refreshTasks();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade400, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.5)),
            ]
          ],
        ),
      ),
    );
  }
}