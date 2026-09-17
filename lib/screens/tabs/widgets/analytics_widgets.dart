import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/app_colors.dart';

// Ortak Formatlayıcı ve Sabitler
String formatMinutes(int totalMinutes) {
  if (totalMinutes == 0) return '0 dk';
  int h = totalMinutes ~/ 60;
  int m = totalMinutes % 60;
  if (h > 0 && m > 0) return '${h}s ${m}dk';
  if (h > 0) return '${h}s';
  return '${m}dk';
}

const List<String> monthNames = [
  '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];

// ---------------------------------------------------------
// 1. ZARİF BOŞ DURUM KARTI (Empty State Card)
// ---------------------------------------------------------
class EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color highlightColor;

  const EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.highlightColor = AppColors.lightBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkGreen.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: highlightColor.withOpacity(0.3),
            offset: const Offset(4, 4),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: highlightColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.darkGreen, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. ÖZET KARTLARI (Summary Cards)
// ---------------------------------------------------------
class AnalyticsSummaryCards extends StatelessWidget {
  final int totalMinutes;
  final int totalSessions;

  const AnalyticsSummaryCards({
    super.key,
    required this.totalMinutes,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.mintGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.darkGreen, width: 4),
              boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2)),
                    child: const Icon(Icons.access_time_filled_rounded, color: AppColors.darkGreen, size: 24)
                ),
                const SizedBox(height: 16),
                Text(formatMinutes(totalMinutes), style: const TextStyle(color: AppColors.darkGreen, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 4),
                const Text('Toplam Süre', style: TextStyle(color: AppColors.darkGreen, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.darkGreen, width: 4),
              boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2)),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.red, size: 24)
                ),
                const SizedBox(height: 16),
                Text('$totalSessions', style: const TextStyle(color: AppColors.red, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Tamamlanan', style: TextStyle(color: AppColors.red, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// 3. AKTİVİTE TAKVİMİ (Calendar Heatmap)
// ---------------------------------------------------------
class CalendarHeatmapWidget extends StatelessWidget {
  final Map<DateTime, int> dailyMinutesMap;
  final Function(DateTime) onDayTapped;

  const CalendarHeatmapWidget({
    super.key,
    required this.dailyMinutesMap,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = dailyMinutesMap.keys.toList()..sort();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkGreen, width: 4),
        boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aktivite Takvimi', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkGreen, width: 2)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.darkGreen, size: 16),
                    const SizedBox(width: 4),
                    Text('${dailyMinutesMap.values.where((v) => v > 0).length} Gün', style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Performans Optimizasyonu: Izgara çizimlerini RepaintBoundary ile sarıyoruz
          RepaintBoundary(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedKeys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0
              ),
              itemBuilder: (context, index) {
                DateTime date = sortedKeys[index];
                int minutes = dailyMinutesMap[date] ?? 0;
                int intensity = 0;
                if (minutes > 0 && minutes <= 30) intensity = 1;
                else if (minutes > 30 && minutes <= 90) intensity = 2;
                else if (minutes > 90) intensity = 3;
                bool isFuture = date.isAfter(DateTime.now());

                return GestureDetector(
                  onTap: () {
                    if (minutes > 0) {
                      HapticFeedback.selectionClick();
                      onDayTapped(date);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : (intensity == 0 ? Colors.grey.shade50 : (intensity == 1 ? AppColors.mintGreen : intensity == 2 ? AppColors.lightBlue : AppColors.darkGreen)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isFuture ? Colors.transparent : (intensity == 0 ? Colors.grey.shade200 : AppColors.darkGreen),
                          width: 2
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                            color: isFuture ? Colors.grey.shade300 : (intensity == 0 ? Colors.grey.shade400 : (intensity == 3 ? Colors.white : AppColors.darkBlue)),
                            fontWeight: FontWeight.w900,
                            fontSize: 14
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
    );
  }
}

// ---------------------------------------------------------
// 4. VERİMLİLİK DAĞILIMI (Bar Chart)
// ---------------------------------------------------------
class ExpandableBarChartWidget extends StatefulWidget {
  final Map<int, int> weekdayStats;
  const ExpandableBarChartWidget({super.key, required this.weekdayStats});

  @override
  State<ExpandableBarChartWidget> createState() => _ExpandableBarChartWidgetState();
}

class _ExpandableBarChartWidgetState extends State<ExpandableBarChartWidget> {
  bool _showBarChart = false;
  final List<String> dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    int maxMins = widget.weekdayStats.values.fold(0, (max, v) => v > max ? v : max);
    if (maxMins == 0) maxMins = 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkGreen, width: 4),
        boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showBarChart = !_showBarChart);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _showBarChart ? AppColors.mintGreen.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: Radius.circular(_showBarChart ? 0 : 20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.darkGreen, width: 2),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, color: AppColors.darkGreen, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Verimlilik Dağılımı', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900)),
                          if (!_showBarChart)
                            const Text('Göster', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                  Icon(_showBarChart ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.darkGreen, size: 28),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: _showBarChart
                ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppColors.darkGreen.withOpacity(0.1), thickness: 2),
                  const SizedBox(height: 24),
                  // Performans Optimizasyonu: Çizimlerin scroll performansını etkilememesi için sınırlandırıyoruz.
                  RepaintBoundary(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        int dayKey = index + 1;
                        int mins = widget.weekdayStats[dayKey] ?? 0;
                        double fillRatio = mins / maxMins;
                        bool isMax = mins == maxMins && mins > 0;

                        return Column(
                          children: [
                            if (mins > 0)
                              Text('${(mins / 60).toStringAsFixed(1)}s', style: TextStyle(color: isMax ? AppColors.darkGreen : Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w900)),
                            if (mins == 0)
                              const SizedBox(height: 14),
                            const SizedBox(height: 8),
                            Container(
                              width: 28,
                              height: 120,
                              decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade300, width: 2)
                              ),
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutExpo,
                                height: 120 * fillRatio,
                                decoration: BoxDecoration(
                                    color: isMax ? AppColors.yellow : AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.darkGreen, width: mins > 0 ? 2 : 0)
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                                dayLabels[index],
                                style: TextStyle(
                                    color: isMax ? AppColors.darkGreen : AppColors.darkBlue,
                                    fontWeight: isMax ? FontWeight.w900 : FontWeight.w700,
                                    fontSize: 12
                                )
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 5. PROJE (KLASÖR) KARTLARI VE RESSAM (Painters)
// ---------------------------------------------------------
class ProjectFolderCard extends StatelessWidget {
  final String folderName;
  final int sessionCount;
  final Color baseColor;
  final VoidCallback onOptionsTapped;
  final VoidCallback onCardTapped;

  const ProjectFolderCard({
    super.key,
    required this.folderName,
    required this.sessionCount,
    required this.baseColor,
    required this.onOptionsTapped,
    required this.onCardTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTapped,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkGreen, width: 4),
          boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.darkBlue),
                onPressed: onOptionsTapped,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.darkGreen, width: 2)
                    ),
                    child: const Icon(Icons.folder_rounded, color: AppColors.darkBlue, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    folderName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.darkGreen, width: 2)
                    ),
                    child: Text(
                      '$sessionCount Seans',
                      style: const TextStyle(color: AppColors.darkBlue, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProjectFolderCard extends StatelessWidget {
  final VoidCallback onTap;
  const AddProjectFolderCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkGreen, width: 4, style: BorderStyle.none),
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: DottedBorderPainter(color: AppColors.darkGreen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkGreen, width: 3)
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.darkGreen, size: 32),
                ),
                const SizedBox(height: 12),
                const Text('Yeni Proje', style: TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  DottedBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final RRect rect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(24));
    canvas.drawRRect(rect, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}