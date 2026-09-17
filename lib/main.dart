import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart'; // YENİ: Bildirim servisi eklendi
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalDatabaseService().init();
  await NotificationService().init(); // YENİ: Bildirim servisi başlatıldı

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PamidoroApp());
}

class PamidoroApp extends StatelessWidget {
  const PamidoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PamiDoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: FirebaseAuth.instance.currentUser != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoadingGuest = false;

  Future<void> _signInAnonymously() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoadingGuest = true);

    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        setState(() => _isLoadingGuest = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.darkGreen, width: 4),
            ),
            title: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.darkBlue, size: 32),
                SizedBox(width: 12),
                Expanded(child: Text('Hoş Geldin!', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w900, fontSize: 24))),
              ],
            ),
            content: const Text(
              'PamiDoro\'yu ilk 5 seans boyunca ücretsiz ve kayıt olmadan deneyebilirsin.\n\nMerak etme, bu sürede verilerin kaybolmaz! Ancak 5 seansın sonunda verilerini korumak, her cihazdan erişebilmek ve uygulamayı kullanmaya devam etmek için kayıt olman gerekecek.',
              style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5, fontWeight: FontWeight.w700),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen())
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkGreen, width: 3),
                      boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]
                  ),
                  child: const Center(
                    child: Text('Anladım, Başla', style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Bağlantı kurulamadı. İnternetinizi kontrol edin.');
      debugPrint("Misafir Giriş Hatası: $e");
      if (mounted) setState(() => _isLoadingGuest = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.darkGreen, width: 3)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -60, left: -40, child: Container(width: 200, height: 200, decoration: BoxDecoration(color: AppColors.mintGreen.withOpacity(0.4), shape: BoxShape.circle))),
          Positioned(top: 150, right: -80, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: AppColors.lightPink.withOpacity(0.4), shape: BoxShape.circle))),
          Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(color: AppColors.lightBlue.withOpacity(0.3), shape: BoxShape.circle))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 12), height: 140, width: 140,
                              decoration: BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.darkGreen, width: 4),
                                  boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))]
                              ),
                              child: const Center(child: Icon(Icons.timer_rounded, color: AppColors.yellow, size: 72)),
                            ),
                            Container(height: 24, width: 48, decoration: BoxDecoration(color: AppColors.mintGreen, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkGreen, width: 3))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.darkGreen, width: 4),
                            boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))]
                        ),
                        child: Column(
                          children: [
                            const Text(
                                'PamiDoro',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.darkGreen, letterSpacing: -1.5)
                            ),
                            const SizedBox(height: 12),
                            Text(
                                'Odaklanma alışkanlıkları baştan yarat. İster kayıt ol, ister hemen keşfet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkBlue.withOpacity(0.8), height: 1.5)
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: _isLoadingGuest ? null : _signInAnonymously,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200), height: 64,
                          decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.darkGreen, width: 4),
                              boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoadingGuest)
                                const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.darkGreen, strokeWidth: 3))
                              else ...[
                                const Text('Üye Olmadan İncele', style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.darkGreen, size: 20),
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                        },
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                              color: AppColors.mintGreen,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.darkGreen, width: 4),
                              boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))]
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mail_rounded, color: AppColors.darkGreen, size: 24),
                              SizedBox(width: 12),
                              Text('E-Posta ile Giriş / Kayıt', style: TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
