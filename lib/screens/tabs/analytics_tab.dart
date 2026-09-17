// File: screens/tabs/analytics_tab.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../services/database_service.dart';
import 'widgets/analytics_widgets.dart'; // Saf UI Kartlar
import 'widgets/analytics_dialogs.dart'; // Dialog ve BottomSheet'ler

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final IDatabaseService _dbService = LocalDatabaseService();
  bool _isLoading = true;

  // Hibrit Kontrol Durumu
  bool _isRolling30Days = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Analiz Verileri
  int _totalMonthlyMinutes = 0;
  int _totalMonthlySessions = 0;
  Map<DateTime, int> _dailyMinutesMap = {};
  Map<int, int> _weekdayStats = {};

  // Klasör Verileri
  Map<String, int> _folderStats = {};

  final List<Color> _folderColors = [
    AppColors.lightBlue,
    AppColors.lightPink,
    AppColors.mintGreen,
    AppColors.yellow,
    AppColors.red,
  ];

  // Menünün Tarih Seçenekleri
  List<Map<String, dynamic>> _monthOptions = [];

  @override
  void initState() {
    super.initState();
    _generateMonthOptions();
    _loadData();
  }

  void _generateMonthOptions() {
    DateTime now = DateTime.now();
    _monthOptions.add({'label': 'Son 30 Gün', 'isRolling': true, 'date': now});
    for (int i = 0; i < 12; i++) {
      DateTime d = DateTime(now.year, now.month - i, 1);
      _monthOptions.add({
        'label': '${monthNames[d.month]} ${d.year}',
        'isRolling': false,
        'date': d
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    DateTime now = DateTime.now();
    List<FocusSession> sessions = [];
    Map<DateTime, int> tempDailyMap = {};

    if (_isRolling30Days) {
      DateTime start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      sessions = await _dbService.getSessionsForDateRange(start, end);
      for (int i = 0; i < 30; i++) {
        DateTime d = start.add(Duration(days: i));
        tempDailyMap[DateTime(d.year, d.month, d.day)] = 0;
      }
    } else {
      DateTime start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      DateTime end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).subtract(const Duration(seconds: 1));
      sessions = await _dbService.getSessionsForDateRange(start, end);
      int daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
      for (int i = 1; i <= daysInMonth; i++) {
        tempDailyMap[DateTime(_selectedMonth.year, _selectedMonth.month, i)] = 0;
      }
    }

    int totalMins = 0;
    int totalSess = sessions.length;
    Map<int, int> tempWeekdayStats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    List<String> allFolders = await _dbService.getAllFolders();
    Map<String, int> tempFolderStats = {};

    for (var f in allFolders) {
      tempFolderStats[f] = 0;
    }

    for (var s in sessions) {
      totalMins += s.durationMinutes;
      DateTime cleanDate = DateTime(s.date.year, s.date.month, s.date.day);
      if (tempDailyMap.containsKey(cleanDate)) {
        tempDailyMap[cleanDate] = tempDailyMap[cleanDate]! + s.durationMinutes;
      }
      int weekday = s.date.weekday;
      tempWeekdayStats[weekday] = (tempWeekdayStats[weekday] ?? 0) + s.durationMinutes;

      if (!tempFolderStats.containsKey(s.folderName)) {
        tempFolderStats[s.folderName] = 0;
      }
      tempFolderStats[s.folderName] = tempFolderStats[s.folderName]! + 1;
    }

    if (mounted) {
      setState(() {
        _totalMonthlyMinutes = totalMins;
        _totalMonthlySessions = totalSess;
        _dailyMinutesMap = tempDailyMap;
        _weekdayStats = tempWeekdayStats;
        _folderStats = tempFolderStats;
        _isLoading = false;
      });
    }
  }

  void _onMonthPickerTapped() async {
    final result = await AnalyticsDialogs.showMonthPicker(
        context,
        _monthOptions,
        _isRolling30Days,
        _selectedMonth
    );

    if (result != null && mounted) {
      setState(() {
        _isRolling30Days = result['isRolling'];
        if (!_isRolling30Days) {
          _selectedMonth = result['date'];
        }
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.darkGreen,
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 80.0,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.background.withOpacity(0.8),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    'İstatistikler',
                    style: TextStyle(color: AppColors.darkBlue, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: GestureDetector(
                onTap: _onMonthPickerTapped,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 2)),
                              child: const Icon(Icons.calendar_month_rounded, color: AppColors.darkGreen, size: 22)
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _isRolling30Days ? 'Son 30 Gün' : '${monthNames[_selectedMonth.month]} ${_selectedMonth.year}',
                            style: const TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)))
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnalyticsSummaryCards(
                    totalMinutes: _totalMonthlyMinutes,
                    totalSessions: _totalMonthlySessions
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: CalendarHeatmapWidget(
                    dailyMinutesMap: _dailyMinutesMap,
                    onDayTapped: (date) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                        builder: (context) => DayDetailsSheet(date: date, onDataChanged: _loadData),
                      );
                    }
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: ExpandableBarChartWidget(weekdayStats: _weekdayStats),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Projeler', style: TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.w900)),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AnalyticsDialogs.showCreateFolderDialog(context, _loadData);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppColors.yellow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.darkGreen, width: 2),
                            boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(2, 2))]
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded, color: AppColors.darkGreen, size: 18),
                            SizedBox(width: 4),
                            Text('Yeni', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == 0) {
                      return AddProjectFolderCard(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            AnalyticsDialogs.showCreateFolderDialog(context, _loadData);
                          }
                      );
                    }
                    String folderName = _folderStats.keys.elementAt(index - 1);
                    int sessionCount = _folderStats.values.elementAt(index - 1);
                    Color cardColor = _folderColors[(index - 1) % _folderColors.length];

                    return ProjectFolderCard(
                        folderName: folderName,
                        sessionCount: sessionCount,
                        baseColor: cardColor,
                        onOptionsTapped: () => AnalyticsDialogs.showFolderOptions(context, folderName, _loadData),
                        onCardTapped: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                              context: context,
                              backgroundColor: AppColors.background,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                              builder: (context) => FolderDetailsSheet(
                                folderName: folderName,
                                isRolling30Days: _isRolling30Days,
                                selectedMonth: _selectedMonth,
                                onDataChanged: _loadData,
                              )
                          );
                        }
                    );
                  },
                  childCount: _folderStats.length + 1,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}