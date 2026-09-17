// File: screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCountryCode = '+90';
  String _selectedCountryName = 'Türkiye';

  bool _isLogin = true;
  bool _isLoading = false;

  final List<Map<String, String>> _allCountries = [
    {'name': 'Türkiye', 'code': '+90'},
    {'name': 'Azerbaycan', 'code': '+994'},
    {'name': 'ABD / Kanada', 'code': '+1'},
    {'name': 'Almanya', 'code': '+49'},
    {'name': 'Arjantin', 'code': '+54'},
    {'name': 'Arnavutluk', 'code': '+355'},
    {'name': 'Avustralya', 'code': '+61'},
    {'name': 'Avusturya', 'code': '+43'},
    {'name': 'Brezilya', 'code': '+54'},
    {'name': 'Belçika', 'code': '+32'},
    {'name': 'Birleşik Krallık', 'code': '+44'},
    {'name': 'Bulgaristan', 'code': '+359'},
    {'name': 'Cezayir', 'code': '+213'},
    {'name': 'Çin', 'code': '+86'},
    {'name': 'Danimarka', 'code': '+45'},
    {'name': 'Endonezya', 'code': '+62'},
    {'name': 'Fas', 'code': '+212'},
    {'name': 'Fransa', 'code': '+33'},
    {'name': 'Güney Afrika', 'code': '+212'},
    {'name': 'Güney Kore', 'code': '+82'},
    {'name': 'Hindistan', 'code': '+91'},
    {'name': 'Hollanda', 'code': '+31'},
    {'name': 'Irak', 'code': '+964'},
    {'name': 'İran', 'code': '+964'},
    {'name': 'İrlanda', 'code': '+31'},
    {'name': 'İspanya', 'code': '+33'},
    {'name': 'İsrail', 'code': '+98'},
    {'name': 'İsveç', 'code': '+46'},
    {'name': 'İsviçre', 'code': '+41'},
    {'name': 'İtalya', 'code': '+34'},
    {'name': 'Japonya', 'code': '+81'},
    {'name': 'Katar', 'code': '+974'},
    {'name': 'Kazakistan', 'code': '+7'},
    {'name': 'Meksika', 'code': '+55'},
    {'name': 'Mısır', 'code': '+20'},
    {'name': 'Nijerya', 'code': '+234'},
    {'name': 'Norveç', 'code': '+47'},
    {'name': 'Özbekistan', 'code': '+7'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'Polonya', 'code': '+48'},
    {'name': 'Portekiz', 'code': '+48'},
    {'name': 'Rusya', 'code': '+7'},
    {'name': 'Suudi Arabistan', 'code': '+966'},
    {'name': 'Türkmenistan', 'code': '+993'},
    {'name': 'Ukrayna', 'code': '+380'},
    {'name': 'Yunanistan', 'code': '+39'},
  ];

  // YENİ: Kullanıcı adı formatını kontrol eden regex (Sadece küçük/büyük harf, rakam, alt çizgi, 3-15 karakter)
  bool _isValidNickname(String nickname) {
    final RegExp nicknameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
    return nicknameRegExp.hasMatch(nickname);
  }

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim().toLowerCase(); // Nickname her zaman küçük harf kaydedilsin
    final phone = _phoneController.text.trim();

    // 1. Temel Boşluk Kontrolü
    if (email.isEmpty || password.isEmpty) {
      _showError('Lütfen e-posta ve şifrenizi eksiksiz girin.');
      return;
    }

    // 2. Kayıt Olma Ekstra Kontrolleri
    if (!_isLogin) {
      if (name.isEmpty || nickname.isEmpty || phone.isEmpty) {
        _showError('Lütfen tüm bilgileri eksiksiz doldurun.');
        return;
      }
      if (phone.length < 7) {
        _showError('Lütfen geçerli bir telefon numarası girin.');
        return;
      }
      if (!_isValidNickname(nickname)) {
        _showError('Kullanıcı adı 3-15 karakter olmalı; sadece harf, rakam ve alt çizgi (_) içermelidir. Boşluk kullanılamaz.');
        return;
      }
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final bool isGuest = currentUser != null && currentUser.isAnonymous;

      if (_isLogin) {
        // GİRİŞ YAPMA İŞLEMİ
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // KAYIT OLMA İŞLEMİ
        final String fullPhone = '$_selectedCountryCode$phone';

        // Veritabanında Nickname kontrolü
        final nicknameCheck = await FirebaseFirestore.instance.collection('users').where('nickname', isEqualTo: nickname).get();
        if (nicknameCheck.docs.isNotEmpty) {
          _showError('Bu kullanıcı adı (@$nickname) başkası tarafından alınmış. Lütfen farklı bir tane seçin.');
          setState(() => _isLoading = false);
          return;
        }

        // Veritabanında Telefon kontrolü
        final phoneCheck = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: fullPhone).get();
        if (phoneCheck.docs.isNotEmpty) {
          _showError('Bu telefon numarası sistemimize zaten kayıtlı.');
          setState(() => _isLoading = false);
          return;
        }

        User? activeUser;

        if (isGuest) {
          final credential = EmailAuthProvider.credential(email: email, password: password);
          final userCredential = await currentUser.linkWithCredential(credential);
          activeUser = userCredential.user;
        } else {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
          activeUser = userCredential.user;
        }

        await activeUser!.updateDisplayName(name);

        await FirebaseFirestore.instance.collection('users').doc(activeUser.uid).set({
          'fullName': name,
          'nickname': nickname,
          'phone': fullPhone,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'dailyGoal': 240,
          'folders': ['Genel Çalışma'],
          'settings': {
            'darkMode': false,
            'notifications': true,
            'keepScreenAwake': true,
            'autoStartBreaks': false,
          },
        }, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      // YENİ: FİREBASE AUTH HATALARINI TÜRKÇELEŞTİRME VE DÜZENLEME
      String message = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';

      switch (e.code) {
        case 'user-not-found':
          message = 'Bu e-posta adresine ait bir hesap bulunamadı.';
          break;
        case 'wrong-password':
          message = 'Girdiğiniz şifre hatalı. Lütfen tekrar deneyin.';
          break;
        case 'invalid-credential':
          message = 'E-posta adresiniz veya şifreniz hatalı.';
          break;
        case 'email-already-in-use':
          message = 'Bu e-posta adresi sistemimizde zaten kayıtlı.';
          break;
        case 'weak-password':
          message = 'Şifreniz çok zayıf. Lütfen en az 6 karakterli daha güçlü bir şifre belirleyin.';
          break;
        case 'invalid-email':
          message = 'Lütfen geçerli bir e-posta adresi formatı (ornek@mail.com) girin.';
          break;
        case 'credential-already-in-use':
          message = 'Bu e-posta adresi başka bir misafir hesabına veya aktif hesaba bağlı.';
          break;
        case 'network-request-failed':
          message = 'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
          break;
        case 'too-many-requests':
          message = 'Üst üste çok fazla hatalı deneme yaptınız. Lütfen biraz bekleyip tekrar deneyin.';
          break;
      }
      _showError(message);
    } catch (e) {
      // YENİ: RAW (ÇİĞ) HATALARI GİZLE, KULLANICI DOSTU MESAJ VER
      debugPrint("KAYIT HATASI DETAYI: $e");
      _showError('Geçici bir sistem sorunu oluştu. Lütfen birazdan tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.darkGreen, width: 3)),
      ),
    );
  }

  void _showCountryCodePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              List<Map<String, String>> filteredCountries = _allCountries;

              void filterSearchResults(String query) {
                setModalState(() {
                  if (query.isNotEmpty) {
                    filteredCountries = _allCountries.where((item) {
                      final countryName = item['name']!.toLowerCase();
                      final countryCode = item['code']!.toLowerCase();
                      final searchLower = query.toLowerCase();
                      return countryName.contains(searchLower) || countryCode.contains(searchLower);
                    }).toList();
                  } else {
                    filteredCountries = _allCountries;
                  }
                });
              }

              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 24),
                        const Text('Ülke Kodu Seç', style: TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (value) => filterSearchResults(value),
                          decoration: InputDecoration(
                            hintText: 'Ülke adı veya kod ara...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkGreen),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 3)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: filteredCountries.isEmpty
                              ? Center(child: Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)))
                              : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredCountries.length,
                            itemBuilder: (context, index) {
                              final item = filteredCountries[index];
                              final isSelected = _selectedCountryCode == item['code'] && _selectedCountryName == item['name'];
                              return ListTile(
                                onTap: () {
                                  setState(() {
                                    _selectedCountryCode = item['code']!;
                                    _selectedCountryName = item['name']!;
                                  });
                                  Navigator.pop(context);
                                },
                                leading: Container(
                                  width: 65,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.lightBlue.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                                  child: Text(item['code']!, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGreen, fontSize: 16)),
                                ),
                                title: Text(item['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: AppColors.darkBlue)),
                                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.red) : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, TextInputType keyboardType = TextInputType.text, bool isPassword = false, TextInputAction textInputAction = TextInputAction.next, Function(String)? onSubmitted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 4)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Telefon Numarası', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _showCountryCodePicker,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkGreen, width: 2)),
                  child: Row(
                    children: [
                      Text(_selectedCountryCode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.darkBlue)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGreen),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '555 123 4567',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 4)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.darkGreen, width: 2)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkBlue), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 90, width: 90,
                    decoration: BoxDecoration(color: AppColors.mintGreen, shape: BoxShape.circle, border: Border.all(color: AppColors.darkGreen, width: 4), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(4, 4))]),
                    child: const Center(child: Icon(Icons.person_add_alt_1_rounded, color: AppColors.darkGreen, size: 40)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(_isLogin ? 'Tekrar Hoş Geldin!' : 'Aramıza Katıl', style: const TextStyle(color: AppColors.darkBlue, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(_isLogin ? 'Odaklanmaya kaldığın yerden devam et.' : 'Detaylı profilini oluştur ve hemen başla.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                const SizedBox(height: 40),

                if (!_isLogin) ...[
                  _buildTextField(label: 'Ad Soyad', hint: 'Örn: Omar Mustafazada', controller: _nameController, keyboardType: TextInputType.name),
                  _buildTextField(label: 'Kullanıcı Adı (Nickname)', hint: 'Örn: omarmustafa', controller: _nicknameController),
                  _buildPhoneField(),
                ],

                _buildTextField(label: 'E-Posta Adresi', hint: 'ornek@mail.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
                _buildTextField(label: 'Şifre', hint: '••••••••', controller: _passwordController, isPassword: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _submitAuth()),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _isLoading ? null : _submitAuth,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), height: 64,
                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.darkGreen, width: 4), boxShadow: const [BoxShadow(color: AppColors.darkGreen, offset: Offset(6, 6))]),
                    child: Center(
                      child: _isLoading ? const CircularProgressIndicator(color: AppColors.darkGreen, strokeWidth: 3) : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol', style: const TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _isLogin = !_isLogin); },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Text(_isLogin ? 'Hesabın yok mu? Hemen Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}