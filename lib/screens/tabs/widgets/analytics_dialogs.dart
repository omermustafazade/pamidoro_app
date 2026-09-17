import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/app_colors.dart';
import '../../../services/database_service.dart';
import 'analytics_widgets.dart';

// ---------------------------------------------------------
// 1. GÜN DETAYLARI (Stateful BottomSheet)
// ---------------------------------------------------------
class DayDetailsSheet extends StatefulWidget {
  final DateTime date;
  final VoidCallback onDataChanged;

  const DayDetailsSheet({super.key, required this.date, required this.onDataChanged});

  @override
  State<DayDetailsSheet> createState() => _DayDetailsSheetState();
}

class _DayDetailsSheetState extends State<DayDetailsSheet> {
  final IDatabaseService _dbService = LocalDatabaseService();
  List<FocusSession> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDayData();
  }

  Future<void> _loadDayData() async {
    sessions = await _dbService.getSessionsByDate(widget.date);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // iPhone Home Indicator için SafeArea
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${widget.date.day.toString().padLeft(2, '0')} ${monthNames[widget.date.month]} ${widget.date.year}', style: const TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.w900)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.lightPink, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 2)),
                  child: Text('${sessions.length} Seans', style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900)),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (sessions.isNotEmpty)
              const Align(alignment: Alignment.centerRight, child: Text('Silmek için sola kaydır', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),

            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppColors.darkGreen)))
            else if (sessions.isEmpty)
              const EmptyStateCard(
                title: 'Kayıt Bulunamadı',
                message: 'Bu tarihte henüz bir çalışma yapmamışsın. Yarın yeni bir başlangıç için harika bir gün!',
                icon: Icons.calendar_month_rounded,
                highlightColor: AppColors.lightBlue,
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    return Dismissible(
                      key: ValueKey(s.id ?? s.hashCode.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        await _dbService.deleteSession(s);
                        setState(() {
                          sessions.removeAt(index);
                        });
                        widget.onDataChanged();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt silindi.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.red));
                        }
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkGreen, width: 3)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.darkGreen, width: 3),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]
                        ),
                        child: Row(
                          children: [
                            Container(height: 16, width: 16, decoration: BoxDecoration(color: AppColors.mintGreen, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.folderName, style: const TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(s.taskName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.darkGreen, width: 2)),
                                    child: Text('${s.durationMinutes} dk', style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, fontWeight: FontWeight.w900))
                                ),
                                const SizedBox(height: 6),
                                Text(s.technique, style: const TextStyle(color: AppColors.darkBlue, fontSize: 11, fontWeight: FontWeight.w800)),
                              ],
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
}

// ---------------------------------------------------------
// 2. KLASÖR/PROJE DETAYLARI (Stateful BottomSheet)
// ---------------------------------------------------------
class FolderDetailsSheet extends StatefulWidget {
  final String folderName;
  final bool isRolling30Days;
  final DateTime selectedMonth;
  final VoidCallback onDataChanged;

  const FolderDetailsSheet({super.key, required this.folderName, required this.isRolling30Days, required this.selectedMonth, required this.onDataChanged});

  @override
  State<FolderDetailsSheet> createState() => _FolderDetailsSheetState();
}

class _FolderDetailsSheetState extends State<FolderDetailsSheet> {
  final IDatabaseService _dbService = LocalDatabaseService();
  List<FocusSession> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolderData();
  }

  Future<void> _loadFolderData() async {
    List<FocusSession> allSessions = await _dbService.getSessionsForFolder(widget.folderName);
    if (!widget.isRolling30Days) {
      sessions = allSessions.where((s) => s.date.month == widget.selectedMonth.month && s.date.year == widget.selectedMonth.year).toList();
    } else {
      DateTime start = DateTime.now().subtract(const Duration(days: 29));
      sessions = allSessions.where((s) => s.date.isAfter(start)).toList();
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalMinutes = 0;
    Map<String, int> techniqueStats = {};
    for(var s in sessions) {
      totalMinutes += s.durationMinutes;
      techniqueStats[s.technique] = (techniqueStats[s.technique] ?? 0) + s.durationMinutes;
    }

    return SafeArea(
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.mintGreen, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 2)),
                  child: const Icon(Icons.folder_rounded, color: AppColors.darkGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(widget.folderName, style: const TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)), child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.darkGreen, width: 3), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer_rounded, color: AppColors.darkGreen, size: 24),
                        const SizedBox(height: 12),
                        Text(formatMinutes(totalMinutes), style: const TextStyle(color: AppColors.darkGreen, fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text('Toplam Süre', style: TextStyle(color: AppColors.darkGreen, fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.darkGreen, width: 3), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.darkBlue, size: 24),
                        const SizedBox(height: 12),
                        Text('${sessions.length}', style: const TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text('Tamamlanan', style: TextStyle(color: AppColors.darkBlue, fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (techniqueStats.isNotEmpty) ...[
              const Text('Kullanılan Teknikler', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: techniqueStats.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 2)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.key, style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900, fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(formatMinutes(e.value), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kayıt Geçmişi', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900)),
                if (sessions.isNotEmpty)
                  const Text('Silmek için sola kaydır', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
                  : sessions.isEmpty
                  ? const EmptyStateCard(
                title: 'Klasör Boş',
                message: 'Bu proje için henüz bir çalışma yapmamışsın. Hedeflerine ulaşmak için harika bir fırsat!',
                icon: Icons.create_new_folder_rounded,
                highlightColor: AppColors.yellow,
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  return Dismissible(
                    key: ValueKey(s.id ?? s.hashCode.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await _dbService.deleteSession(s);
                      setState(() {
                        sessions.removeAt(index);
                      });
                      widget.onDataChanged();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt silindi.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.red));
                      }
                    },
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkGreen, width: 3)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.darkGreen, width: 3),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.taskName, style: const TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text('${s.date.day.toString().padLeft(2, '0')}/${s.date.month.toString().padLeft(2, '0')}/${s.date.year}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkGreen, width: 2)),
                              child: Text('${s.durationMinutes} dk', style: const TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w900))
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
}

// ---------------------------------------------------------
// 3. GENEL YÖNETİCİ DİALOG'LARI (Helpers)
// ---------------------------------------------------------
class AnalyticsDialogs {

  static Future<Map<String, dynamic>?> showMonthPicker(
      BuildContext context,
      List<Map<String, dynamic>> monthOptions,
      bool isRolling30Days,
      DateTime selectedMonth
      ) {
    HapticFeedback.selectionClick();
    int initialIndex = monthOptions.indexWhere((opt) {
      if (isRolling30Days && opt['isRolling'] == true) return true;
      if (!isRolling30Days && !opt['isRolling'] && opt['date'].year == selectedMonth.year && opt['date'].month == selectedMonth.month) return true;
      return false;
    });
    if (initialIndex == -1) initialIndex = 0;
    int selectedSpinnerIndex = initialIndex;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: AppColors.darkGreen, width: 4),
          ),
          child: SafeArea(
            bottom: true,
            child: SizedBox(
              height: 380,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 24),
                  const Text('Dönem Seç', style: TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: initialIndex),
                      itemExtent: 55,
                      magnification: 1.2,
                      squeeze: 1.1,
                      useMagnifier: true,
                      onSelectedItemChanged: (int index) {
                        HapticFeedback.selectionClick();
                        selectedSpinnerIndex = index;
                      },
                      children: List<Widget>.generate(monthOptions.length, (int index) {
                        return Center(
                          child: Text(
                            monthOptions[index]['label'],
                            style: const TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(context, monthOptions[selectedSpinnerIndex]);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.darkGreen, width: 4),
                          boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                        ),
                        child: const Center(
                          child: Text('Göster', style: TextStyle(color: AppColors.darkGreen, fontSize: 20, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showFolderOptions(BuildContext context, String folderName, VoidCallback onDataChanged) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppColors.darkGreen, width: 4),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text(folderName, style: const TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                _buildActionOptionTile(
                  icon: Icons.edit_rounded,
                  label: 'Yeniden Adlandır',
                  color: AppColors.yellow,
                  onTap: () {
                    Navigator.pop(context);
                    showRenameFolderDialog(context, folderName, onDataChanged);
                  },
                ),
                if (folderName != 'Genel Çalışma') ...[
                  const SizedBox(height: 16),
                  _buildActionOptionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Projeyi Sil',
                    color: AppColors.red,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      showDeleteFolderConfirmation(context, folderName, onDataChanged);
                    },
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildActionOptionTile({required IconData icon, required String label, required Color color, Color textColor = AppColors.darkBlue, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkGreen, width: 3),
          boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  static void showCreateFolderDialog(BuildContext context, VoidCallback onDataChanged) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.darkGreen, width: 4)),
          title: const Text('Yeni Proje', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Örn: Algoritma Analizi',
              hintStyle: TextStyle(color: Colors.grey.shade400),
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
                if (controller.text.trim().isNotEmpty) {
                  await LocalDatabaseService().createNewFolder(controller.text.trim());
                  onDataChanged();
                  if (context.mounted) Navigator.pop(context);
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
                child: const Text('Oluştur', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showRenameFolderDialog(BuildContext context, String oldName, VoidCallback onDataChanged) {
    TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.darkGreen, width: 4)),
          title: const Text('Projeyi Düzenle', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
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
                if (controller.text.trim().isNotEmpty && controller.text.trim() != oldName) {
                  await LocalDatabaseService().renameFolder(oldName, controller.text.trim());
                  onDataChanged();
                  if (context.mounted) Navigator.pop(context);
                } else {
                  Navigator.pop(context);
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
                child: const Text('Güncelle', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showDeleteFolderConfirmation(BuildContext context, String folderName, VoidCallback onDataChanged) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.darkGreen, width: 4)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('Projeyi Sil', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '"$folderName" projesini siliyorsun. Bu projeye ait geçmiş odaklanma kayıtlarına (çalışmalara) ne yapalım?',
                style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.4, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await LocalDatabaseService().deleteFolder(folderName, moveToGeneral: true);
                  onDataChanged();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proje silindi, kayıtlar "Genel Çalışma" klasörüne taşındı.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), backgroundColor: AppColors.darkGreen, behavior: SnackBarBehavior.floating));
                  }
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 3), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]),
                  child: const Center(child: Text('Genele Taşı', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 16))),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await LocalDatabaseService().deleteFolder(folderName, moveToGeneral: false);
                  onDataChanged();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proje ve içindeki tüm kayıtlar kalıcı olarak silindi.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
                  }
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.red, width: 3), boxShadow: const [BoxShadow(color: AppColors.red, offset: Offset(3, 3))]),
                  child: const Center(child: Text('Kalıcı Olarak Sil', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 16))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 16))),
          ],
        );
      },
    );
  }
}