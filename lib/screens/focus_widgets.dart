import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../utils/app_colors.dart';

/// 1. ZİHİNSEL HAZIRLIK (MINDFULNESS) EKRANI (HAREKETLİ NEFES ANİMASYONU EKLENDİ)
class MindfulnessOverlay extends StatefulWidget {
  final bool isPreparing;
  final int countdown;
  final VoidCallback onCancel;
  final Color primaryColor;

  const MindfulnessOverlay({
    super.key,
    required this.isPreparing,
    required this.countdown,
    required this.onCancel,
    required this.primaryColor,
  });

  @override
  State<MindfulnessOverlay> createState() => _MindfulnessOverlayState();
}

class _MindfulnessOverlayState extends State<MindfulnessOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    // 1 saniyede büyür, 1 saniyede küçülür (Nefes alıp verme ritmi)
    _breathingController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000)
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPreparing) return const SizedBox.shrink();

    Color textColor = (widget.primaryColor == AppColors.yellow || widget.primaryColor == AppColors.lightPink || widget.primaryColor == AppColors.mintGreen || widget.primaryColor == AppColors.lightBlue)
        ? AppColors.darkBlue
        : Colors.white;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: widget.primaryColor.withOpacity(0.9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.air_rounded, color: textColor, size: 80),
              const SizedBox(height: 32),
              Text(
                  'Derin bir nefes al...',
                  style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5)
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: textColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor, width: 2)
                ),
                child: Text(
                    'Odaklanmaya hazırlanıyorsun',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w900)
                ),
              ),
              const SizedBox(height: 64),
              // YENİ: Saniyeye bağlı nefes alma (büyüyüp/küçülme) efekti
              AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    final scale = 1.0 + (_breathingController.value * 0.2); // %100 ile %120 arası boyut değiştirir
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        height: 140, width: 140,
                        decoration: BoxDecoration(
                            color: widget.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: textColor, width: 6),
                            boxShadow: [
                              BoxShadow(color: textColor.withOpacity(0.5), offset: const Offset(8, 8))
                            ]
                        ),
                        child: Center(
                            child: Text(
                                '${widget.countdown}',
                                style: TextStyle(color: textColor, fontSize: 64, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()])
                            )
                        ),
                      ),
                    );
                  }
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBlue, width: 3),
                      boxShadow: const [BoxShadow(color: AppColors.darkBlue, offset: Offset(4, 4))]
                  ),
                  child: const Text('İptal Et', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. 20-20-20 GÖZ DİNLENDİRME BİLDİRİMİ
class EyeRestOverlay extends StatelessWidget {
  final bool isVisible;
  const EyeRestOverlay({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      top: isVisible ? 60 : -120,
      left: 24, right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.mintGreen,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.darkGreen, width: 4),
            boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))]
        ),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 2)),
                child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.darkGreen, size: 28)
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gözlerini Dinlendir', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('20 sn boyunca uzağa odaklan.', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Dönen Kesik Çizgili Halka Boyayıcı
class DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedRingPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const int dashCount = 24;
    const double sweepAngle = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * sweepAngle, sweepAngle * 0.5, false, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. YENİLENMİŞ, NEO-BRUTALIST SAYAÇ DAİRESİ
class TimerCircleDisplay extends StatelessWidget {
  final bool isRunning;
  final double progress;
  final String formattedTime;
  final bool isFlowtime;
  final Color themeColor;
  final double growthFactor;
  final Animation<double> breathingAnimation;
  final Animation<double> rotationAnimation;
  final int sessionCount;

  const TimerCircleDisplay({
    super.key,
    required this.isRunning,
    required this.progress,
    required this.formattedTime,
    required this.isFlowtime,
    required this.themeColor,
    required this.growthFactor,
    required this.breathingAnimation,
    required this.rotationAnimation,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: Listenable.merge([breathingAnimation, rotationAnimation]),
        builder: (context, child) {
          double circleSize = math.min(MediaQuery.of(context).size.width * 0.75, 340);
          return Transform.scale(
            scale: isRunning ? breathingAnimation.value : 1.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: rotationAnimation.value * 2 * math.pi,
                  child: SizedBox(
                    width: circleSize + 40,
                    height: circleSize + 40,
                    child: CustomPaint(painter: DashedRingPainter(color: AppColors.darkGreen.withOpacity(isRunning ? 0.3 : 0.1), strokeWidth: 4)),
                  ),
                ),
                Container(
                  width: circleSize, height: circleSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkGreen, width: 6),
                    boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(8, 8))],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: circleSize - 20, height: circleSize - 20,
                        child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: progress, end: progress),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, _) => CircularProgressIndicator(value: value, color: themeColor, strokeWidth: 16, strokeCap: StrokeCap.square)
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            child: Icon(
                                growthFactor > 0.8 ? Icons.local_florist_rounded : Icons.eco_rounded,
                                color: Color.lerp(Colors.brown.shade400, AppColors.darkGreen, growthFactor),
                                size: 32 + (growthFactor * 24)
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                    formattedTime,
                                    style: TextStyle(color: AppColors.darkGreen, fontSize: isFlowtime ? 76 : 96, fontWeight: FontWeight.w900, letterSpacing: -4, fontFeatures: const [FontFeature.tabularFigures()])
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkGreen, width: 3)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department_rounded, color: AppColors.darkGreen, size: 18),
                                const SizedBox(width: 6),
                                Text('Bugün $sessionCount. Seans', style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }
}

/// 4. YENİLENMİŞ ALT GÖREV KARTLARI
class PremiumSubtaskSection extends StatelessWidget {
  final List<Map<String, dynamic>> subtasks;
  final VoidCallback onAddPressed;
  final Function(int) onToggle;
  final Function(int) onDelete;
  final Color themeColor;

  const PremiumSubtaskSection({
    super.key, required this.subtasks, required this.onAddPressed, required this.onToggle, required this.onDelete, required this.themeColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alt Görevler', style: TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
              GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkGreen, width: 3), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(3, 3))]),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, color: AppColors.darkGreen, size: 20),
                      SizedBox(width: 6),
                      Text('Ekle', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w900, fontSize: 16))
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (subtasks.isEmpty)
            Center(
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Büyük işleri küçük adımlara böl.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5)))
            )
          else
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero, itemCount: subtasks.length,
              itemBuilder: (context, index) {
                final isDone = subtasks[index]['isDone'];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDone ? Colors.grey.shade400 : AppColors.darkGreen, width: 3),
                    boxShadow: isDone ? [] : const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: GestureDetector(
                      onTap: () => onToggle(index),
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200), width: 36, height: 36,
                          decoration: BoxDecoration(color: isDone ? AppColors.darkGreen : Colors.white, border: Border.all(color: isDone ? AppColors.darkGreen : AppColors.darkGreen, width: 3), borderRadius: BorderRadius.circular(10)),
                          child: isDone ? const Icon(Icons.check_rounded, size: 24, color: Colors.white) : null
                      ),
                    ),
                    title: Text(
                        subtasks[index]['title'],
                        style: TextStyle(color: isDone ? Colors.grey.shade500 : AppColors.darkBlue, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5, decoration: isDone ? TextDecoration.lineThrough : null)
                    ),
                    trailing: GestureDetector(
                        onTap: () => onDelete(index),
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 2)), child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20))
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}