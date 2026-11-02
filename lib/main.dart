// ============================================================================
// MICROBIOLOGY & IMMUNOLOGY ACADEMIC PORTAL — NATIVE 2026 EDITION
// Faculty of Pharmacy • Beni-Suef University (BSU) & National University (BSNU)
// 100% Native Flutter UI (Zero WebView / Zero Google Apps Script Banner)
// ============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

typedef JsonMap = Map<String, dynamic>;
typedef StringMenuItem = DropdownMenuItem<String>;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MicroDeptFlutterApp());
}

/// ضع رابط الـ Web App الذي نسخته من Google Apps Script هنا (الذي ينتهي بـ /exec)
const String kBaseWebAppUrl =
    'https://script.google.com/macros/s/AKfycbygFGReaYRWp4gZqhjkc7iTbJXhfxC3rq5-w_qhYxcq9UCgfFQlOUOvC7MPf7En-FnG4A/exec';

// ============================================================================
// 2026 DESIGN SYSTEM PALETTE & CONSTANTS
// ============================================================================
class AppColors {
  static const Color navyBar = Color(0xFF161B29);
  static const Color navyDeep = Color(0xFF0F172A);
  static const Color emeraldDark = Color(0xFF0B4A40);
  static const Color emeraldMid = Color(0xFF0D3834);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldSoft = Color(0xFFECFDF5);
  static const Color gold = Color(0xFFF5B82E);
  static const Color goldSoft = Color(0xFFFEF3C7);
  static const Color goldDark = Color(0xFFB45309);
  static const Color bgSurface = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color danger = Color(0xFFF43F5E);
  static const Color dangerSoft = Color(0xFFFFE4E6);
  static const Color bsnuBlue = Color(0xFF2563EB);
  static const Color bsnuSoft = Color(0xFFEFF6FF);

  static const String deptLogo =
      'https://lh3.googleusercontent.com/d/1JIydTyv1jIsJzTiGwIaACozrlWr8PJen';
  static const String bsnuLogo =
      'https://lh3.googleusercontent.com/d/1aYPB-QbJcJYdktphL-wXj1OcZtZwcMTF';
  static const String bsuLogo =
      'https://lh3.googleusercontent.com/d/1uHzJgfOLkNfFM-MIcyvLLy3Jvd0yrw6T';

  static const List<String> defaultSubjects = [
    'Basic Microbiology',
    'Parasitology',
    'Biotechnology',
    'Pharmaceutical Microbiology',
    'Medical Microbiology',
    'Cell Biology',
    'Public Health',
    'Infection Control',
    'Antimicrobial Stewardship',
  ];
}

// ============================================================================
// NATIVE REST API CLIENT FOR GOOGLE APPS SCRIPT (HANDLES 302 REDIRECTS)
// ============================================================================
class PortalApiService {
  static Future<JsonMap> call(
    String action, [
    JsonMap? payload,
  ]) async {
    final JsonMap bodyData = {
      'action': action,
      if (payload != null) ...payload,
    };

    try {
      final client = http.Client();
      final request = http.Request('POST', Uri.parse(kBaseWebAppUrl))
        ..followRedirects = false
        ..headers['Content-Type'] = 'text/plain;charset=utf-8'
        ..body = jsonEncode(bodyData);

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      // Google Apps Script returns 302 Redirect to script.googleusercontent.com
      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final getRes = await http
              .get(Uri.parse(redirectUrl))
              .timeout(const Duration(seconds: 45));
          client.close();
          return _decodeSafe(getRes.body);
        }
      }

      client.close();
      return _decodeSafe(response.body);
    } catch (e) {
      return {
        'success': false,
        'found': false,
        'message': 'Connection error: $e',
      };
    }
  }

  static JsonMap _decodeSafe(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is JsonMap) return decoded;
      return {'success': true, 'data': decoded};
    } catch (_) {
      return {
        'success': false,
        'found': false,
        'message':
            'Invalid server response. Make sure you deployed the updated Code.gs as Web App (Anyone).',
      };
    }
  }
}

// ============================================================================
// FACEBOOK-STYLE FLOATING TOP CIRCULAR REFRESH INDICATOR
// ============================================================================
class TopFloatingCircularLoader extends StatelessWidget {
  final bool isLoading;
  final String? label;

  const TopFloatingCircularLoader({
    super.key,
    required this.isLoading,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isLoading,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        offset: isLoading ? const Offset(0, 0) : const Offset(0, -2.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isLoading ? 1.0 : 0.0,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              padding: EdgeInsets.symmetric(
                horizontal: label != null ? 16 : 11,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.65),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDeep.withOpacity(0.18),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.emeraldDark,
                      ),
                    ),
                  ),
                  if (label != null && label!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Text(
                      label!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyBar,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ROOT APPLICATION WIDGET
// ============================================================================
class MicroDeptFlutterApp extends StatelessWidget {
  const MicroDeptFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microbiology & Immunology Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgSurface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.emeraldDark,
          primary: AppColors.navyBar,
          secondary: AppColors.gold,
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainAdminSuperShell(),
    );
  }
}

// ============================================================================
// MAIN SHELL: DOCTOR ADMIN + SUPER ADMIN
// - Pre-Login: Smooth horizontal sliding + bottom segmented tabs + edge handle
// - Post-Login: Sliding is LOCKED; opposite role becomes a sleek TOP AppBar button
// ============================================================================
class MainAdminSuperShell extends StatefulWidget {
  const MainAdminSuperShell({super.key});

  @override
  State<MainAdminSuperShell> createState() => _MainAdminSuperShellState();
}

class _MainAdminSuperShellState extends State<MainAdminSuperShell> {
  final PageController _pageController = PageController(initialPage: 0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentPageIndex = 0; // 0 = Doctor Admin, 1 = Super Admin
  bool _isDoctorLoggedIn = false;
  bool _isSuperAdminLoggedIn = false;

  bool _globalLoading = false;
  String? _loadingMessage;

  final GlobalKey<DoctorPortalNativePageState> _doctorPageKey = GlobalKey();
  final GlobalKey<SuperAdminNativePageState> _superPageKey = GlobalKey();

  /// هل المستخدم سجل دخول في أي بوابة حالياً؟
  bool get _isAnyLoggedIn => _isDoctorLoggedIn || _isSuperAdminLoggedIn;

  void _setGlobalLoading(bool loading, [String? msg]) {
    if (!mounted) return;
    setState(() {
      _globalLoading = loading;
      _loadingMessage = msg;
    });
  }

  Future<void> _switchToRolePage(int index, {bool showSpinner = false}) async {
    if (_currentPageIndex == index) return;

    if (showSpinner) {
      _setGlobalLoading(
        true,
        index == 1 ? 'Switching to Super Admin...' : 'Switching to Doctor Admin...',
      );
    }

    setState(() {
      _currentPageIndex = index;
    });

    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }

    if (showSpinner) {
      await Future.delayed(const Duration(milliseconds: 350));
      _setGlobalLoading(false);
    }
  }

  void _openStudentPortalModal() async {
    _setGlobalLoading(true, 'Opening Student Portal...');
    await Future.delayed(const Duration(milliseconds: 280));
    _setGlobalLoading(false);
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const StudentPortalNativeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _refreshActivePage() {
    if (_currentPageIndex == 0) {
      _doctorPageKey.currentState?.refreshData();
    } else {
      _superPageKey.currentState?.refreshData();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSuperAdmin = _currentPageIndex == 1;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildNavigationDrawer(isSuperAdmin),
      appBar: AppBar(
        backgroundColor: AppColors.navyBar,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isSuperAdmin
                    ? AppColors.gold.withOpacity(0.16)
                    : AppColors.emerald.withOpacity(0.18),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isSuperAdmin ? AppColors.gold : AppColors.emerald,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuperAdmin
                        ? Icons.shield_rounded
                        : Icons.medical_information_rounded,
                    size: 14,
                    color: isSuperAdmin
                        ? AppColors.gold
                        : AppColors.emeraldLight,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isSuperAdmin ? 'Super Admin' : 'Doctor Admin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSuperAdmin
                          ? AppColors.gold
                          : AppColors.emeraldLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MICROBIOLOGY & IMMUNOLOGY',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Faculty of Pharmacy • BSU & BSNU',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ==================================================================
          // POST-LOGIN TOP ROLE SWITCH BUTTON:
          // يظهر فوق في الـ AppBar بمجرد تسجيل الدخول بدلاً من الـ Sliding!
          // إذا كنت داخل Doctor Admin يظهر زر Super Admin فوق، والعكس صحيح
          // ==================================================================
          if (_isAnyLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: OutlinedButton.icon(
                onPressed: () =>
                    _switchToRolePage(isSuperAdmin ? 0 : 1, showSpinner: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSuperAdmin
                      ? AppColors.emeraldLight
                      : AppColors.gold,
                  side: BorderSide(
                    color: isSuperAdmin
                        ? AppColors.emeraldLight.withOpacity(0.7)
                        : AppColors.gold.withOpacity(0.8),
                    width: 1.3,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.06),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: Icon(
                  isSuperAdmin
                      ? Icons.medical_services_rounded
                      : Icons.admin_panel_settings_rounded,
                  size: 15,
                ),
                label: Text(
                  isSuperAdmin ? 'Doctor Admin' : 'Super Admin',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: _refreshActivePage,
          ),

          Padding(
            padding: const EdgeInsets.only(right: 10, left: 2),
            child: ElevatedButton.icon(
              onPressed: _openStudentPortalModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF111827),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              icon: const Icon(Icons.school_rounded, size: 15),
              label: const Text(
                'Students',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
        // شريط التبديل السفلي يظهر فقط قبل تسجيل الدخول لتسهيل السحب والتبديل
        bottom: !_isAnyLoggedIn
            ? PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Container(
                  color: AppColors.navyDeep,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _switchToRolePage(0, showSpinner: true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: !isSuperAdmin
                                  ? AppColors.emeraldDark
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !isSuperAdmin
                                    ? AppColors.emerald.withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '👨‍🏫 Doctor Admin Portal',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: !isSuperAdmin
                                    ? AppColors.gold
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _switchToRolePage(1, showSpinner: true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSuperAdmin
                                  ? AppColors.emeraldDark
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSuperAdmin
                                    ? AppColors.gold.withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🛡️ Super Admin (Master)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isSuperAdmin
                                    ? AppColors.gold
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          // ==================================================================
          // PAGEVIEW WITH CONDITIONAL SCROLL PHYSICS:
          // - قبل الـ Log In: BouncingScrollPhysics (تقدر تعمل Sliding بحرية)
          // - بعد الـ Log In: NeverScrollableScrollPhysics (يتقفل الـ Sliding تماماً)
          // ==================================================================
          PageView(
            controller: _pageController,
            physics: _isAnyLoggedIn
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (idx) {
              setState(() {
                _currentPageIndex = idx;
              });
            },
            children: [
              DoctorPortalNativePage(
                key: _doctorPageKey,
                onLoginStateChanged: (loggedIn) {
                  setState(() {
                    _isDoctorLoggedIn = loggedIn;
                  });
                },
                onLoadingChanged: _setGlobalLoading,
              ),
              SuperAdminNativePage(
                key: _superPageKey,
                onLoginStateChanged: (loggedIn) {
                  setState(() {
                    _isSuperAdminLoggedIn = loggedIn;
                  });
                },
                onLoadingChanged: _setGlobalLoading,
              ),
            ],
          ),

          // مقبض السحب الجانبي يظهر فقط قبل تسجيل الدخول
          if (!_isAnyLoggedIn)
            Positioned(
              right: isSuperAdmin ? null : 0,
              left: isSuperAdmin ? 0 : null,
              top: MediaQuery.of(context).size.height * 0.38,
              child: GestureDetector(
                onTap: () => _switchToRolePage(
                  isSuperAdmin ? 0 : 1,
                  showSpinner: true,
                ),
                onHorizontalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < -150 && !isSuperAdmin) {
                    _switchToRolePage(1, showSpinner: true);
                  } else if ((details.primaryVelocity ?? 0) > 150 &&
                      isSuperAdmin) {
                    _switchToRolePage(0, showSpinner: true);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.navyBar.withOpacity(0.94),
                    borderRadius: BorderRadius.horizontal(
                      left:
                          isSuperAdmin ? Radius.zero : const Radius.circular(14),
                      right:
                          isSuperAdmin ? const Radius.circular(14) : Radius.zero,
                    ),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuperAdmin
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        color: AppColors.gold,
                        size: 15,
                      ),
                      const SizedBox(height: 6),
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          isSuperAdmin ? 'DOCTOR ADMIN' : 'SUPER ADMIN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ==================================================================
          // FACEBOOK-STYLE TOP CIRCULAR LOADING SPINNER PILL
          // ==================================================================
          TopFloatingCircularLoader(
            isLoading: _globalLoading,
            label: _loadingMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(bool isSuperAdmin) {
    return Drawer(
      backgroundColor: AppColors.navyBar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.emeraldDark, AppColors.navyDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.gold, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        AppColors.deptLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.biotech_rounded,
                          color: AppColors.emeraldDark,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MICROBIOLOGY & IMMUNOLOGY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Faculty of Pharmacy • BSU & BSNU',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              selected: !isSuperAdmin,
              selectedTileColor: Colors.white10,
              leading: const Icon(
                Icons.medical_information_rounded,
                color: AppColors.emeraldLight,
              ),
              title: const Text(
                'Doctor Admin Portal (الرئيسية)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'مراجعة الأعذار الطبية وغياب الطلاب',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _switchToRolePage(0, showSpinner: true);
              },
            ),
            ListTile(
              selected: isSuperAdmin,
              selectedTileColor: Colors.white10,
              leading: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.gold,
              ),
              title: const Text(
                'Super Admin Control',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'إدارة حسابات الدكاترة وسجل التعديلات',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _switchToRolePage(1, showSpinner: true);
              },
            ),
            const Divider(color: Colors.white24, height: 24),
            ListTile(
              leading:
                  const Icon(Icons.school_rounded, color: Colors.amberAccent),
              title: const Text(
                'Student Portal (بوابة الطلاب)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'الاستعلام عن الغياب ورفع الأعذار الطبية',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _openStudentPortalModal();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isAnyLoggedIn
                    ? '🔒 Swipe Lock Active (Use top bar button to switch portals)'
                    : '↔️ Swipe left or right to switch before signing in',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. DOCTOR ADMIN NATIVE PORTAL (LOGIN + EXCUSES REVIEW + ATTENDANCE INSPECTOR)
// ============================================================================
class DoctorPortalNativePage extends StatefulWidget {
  final ValueChanged<bool> onLoginStateChanged;
  final void Function(bool loading, [String? msg]) onLoadingChanged;

  const DoctorPortalNativePage({
    super.key,
    required this.onLoginStateChanged,
    required this.onLoadingChanged,
  });

  @override
  State<DoctorPortalNativePage> createState() => DoctorPortalNativePageState();
}

class DoctorPortalNativePageState extends State<DoctorPortalNativePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _newUserCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();

  bool _isLoggedIn = false;
  bool _obscurePass = true;
  bool _showCredentialsDrawer = false;
  String? _loginError;
  String? _credMessage;
  bool _credSuccess = false;

  String _doctorName = '';
  String _doctorUsername = '';
  String _doctorPassword = '';

  String _selectedUni = 'Beni-Suef University';
  String _selectedProgram = 'General Program';
  String _selectedSubject = AppColors.defaultSubjects.first;

  List<JsonMap> _allExcuseRequests = [];
  List<JsonMap> _filteredRequests = [];
  int _selectedStudentIndex = 0;
  int _selectedPhotoIndex = 0;

  JsonMap? _currentAttendanceRecord;
  bool _loadingAttendanceRecord = false;
  String? _statusActionMessage;
  bool _statusActionSuccess = true;

  Future<void> refreshData() async {
    if (!_isLoggedIn) return;
    await _loadAllStudents();
  }

  Future<void> _doDoctorLogin() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) {
      setState(() => _loginError = 'Please enter both username and password.');
      return;
    }

    setState(() => _loginError = null);
    widget.onLoadingChanged(true, 'Verifying Doctor Credentials...');

    final res = await PortalApiService.call('verifyDoctorLogin', {
      'username': u,
      'password': p,
    });

    widget.onLoadingChanged(false);

    if (res['success'] == true) {
      setState(() {
        _isLoggedIn = true;
        _doctorName = (res['doctorName'] ?? u).toString();
        _doctorUsername = (res['username'] ?? u).toString();
        _doctorPassword = p;
        _newUserCtrl.text = _doctorUsername;
        _newPassCtrl.text = _doctorPassword;
      });
      widget.onLoginStateChanged(true);
      await _loadAllStudents();
    } else {
      setState(() {
        _loginError =
            (res['message'] ?? 'Invalid doctor credentials.').toString();
      });
    }
  }

  void _logoutDoctor() {
    setState(() {
      _isLoggedIn = false;
      _passCtrl.clear();
      _allExcuseRequests.clear();
      _filteredRequests.clear();
      _currentAttendanceRecord = null;
      _showCredentialsDrawer = false;
    });
    widget.onLoginStateChanged(false);
  }

  Future<void> _loadAllStudents() async {
    widget.onLoadingChanged(true, 'Syncing Excuse Requests...');
    final res = await PortalApiService.call('getStudents');
    widget.onLoadingChanged(false);

    final rawList = res['students'] ?? res['data'];
    if (rawList is List) {
      setState(() {
        _allExcuseRequests =
            rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = _allExcuseRequests.where((s) {
      final uniMatch = (s['university'] ?? '').toString() == _selectedUni;
      final progMatch = (s['program'] ?? '').toString() == _selectedProgram;
      final subjMatch = (s['subject'] ?? '').toString() == _selectedSubject;
      final name = (s['name'] ?? '').toString().toLowerCase();
      final stId = (s['studentId'] ?? '').toString().toLowerCase();
      final qMatch = q.isEmpty || name.contains(q) || stId.contains(q);
      return uniMatch && progMatch && subjMatch && qMatch;
    }).toList();

    setState(() {
      _filteredRequests = filtered;
      _selectedStudentIndex = 0;
      _selectedPhotoIndex = 0;
      _statusActionMessage = null;
    });

    if (_filteredRequests.isNotEmpty) {
      _loadAttendanceForSelectedStudent(_filteredRequests[0]);
    } else {
      setState(() => _currentAttendanceRecord = null);
    }
  }

  Future<void> _loadAttendanceForSelectedStudent(
    JsonMap student,
  ) async {
    setState(() {
      _loadingAttendanceRecord = true;
      _currentAttendanceRecord = null;
    });

    final res = await PortalApiService.call('getStudentAttendanceForDoctor', {
      'university': student['university'],
      'program': student['program'],
      'subject': student['subject'],
      'studentId': student['studentId'],
    });

    if (!mounted) return;
    setState(() {
      _loadingAttendanceRecord = false;
      _currentAttendanceRecord = res;
    });
  }

  Future<void> _changeExcuseStatus(String newStatus) async {
    if (_filteredRequests.isEmpty) return;
    final current = _filteredRequests[_selectedStudentIndex];
    final row = current['row'];

    widget.onLoadingChanged(
      true,
      newStatus == 'Approved'
          ? 'Approving & Syncing Attendance Sheet...'
          : 'Rejecting Excuse Request...',
    );

    final res = await PortalApiService.call('updateStatus', {
      'row': row,
      'status': newStatus,
      'actorDoctorName': _doctorName,
      'actorUsername': _doctorUsername,
    });

    widget.onLoadingChanged(false);

    setState(() {
      current['status'] = newStatus;
      for (final item in _allExcuseRequests) {
        if (item['row'] == row) {
          item['status'] = newStatus;
        }
      }
      _statusActionSuccess = newStatus == 'Approved';
      final sync = res['sync'] is Map ? res['sync'] as Map : {};
      if (newStatus == 'Approved') {
        if (sync['updated'] == true) {
          final secs = (sync['sections'] as List?)?.join(', ') ?? '';
          _statusActionMessage =
              '✅ Approved — Converted to (E) in Section $secs';
        } else {
          _statusActionMessage = '✅ Approved (${sync['note'] ?? 'Synced'})';
        }
      } else {
        _statusActionMessage = '✖ Rejected — Locked from re-submitting.';
      }
    });

    await _loadAttendanceForSelectedStudent(current);
  }

  Future<void> _updateOwnCredentials() async {
    final newU = _newUserCtrl.text.trim();
    final newP = _newPassCtrl.text.trim();
    if (newU.isEmpty || newP.isEmpty) return;

    widget.onLoadingChanged(true, 'Updating Doctor Credentials...');
    final res = await PortalApiService.call('updateOwnDoctorCredentials', {
      'currentUsername': _doctorUsername,
      'currentPassword': _doctorPassword,
      'newUsername': newU,
      'newPassword': newP,
    });
    widget.onLoadingChanged(false);

    setState(() {
      _credSuccess = res['success'] == true;
      _credMessage = (res['message'] ?? '').toString();
      if (_credSuccess) {
        _doctorUsername = (res['newUsername'] ?? newU).toString();
        _doctorPassword = (res['newPassword'] ?? newP).toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isLoggedIn) {
      return _buildLoginView();
    }
    return _buildDoctorDashboardView();
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withOpacity(0.08),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.gold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      AppColors.deptLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_information_rounded,
                        size: 42,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '👨‍🏫 DOCTOR ADMIN GATEWAY',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emeraldDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Doctor Portal Login',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your personal doctor username & password to review student excuses and attendance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                _buildModernTextField(
                  controller: _userCtrl,
                  label: 'Doctor Username',
                  hint: 'Enter username (e.g. doctor1)',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _buildModernTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: 'Enter password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  onSubmitted: (_) => _doDoctorLogin(),
                ),
                if (_loginError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _doDoctorLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldDark,
                      foregroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Sign In to Dashboard →',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe_rounded,
                        size: 15, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Swipe left before login to access Super Admin',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorDashboardView() {
    return RefreshIndicator(
      color: AppColors.emeraldDark,
      onRefresh: _loadAllStudents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 48),
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.3),
                  radius: 1.4,
                  colors: [
                    Color(0xFF0F4C42),
                    AppColors.emeraldMid,
                    AppColors.navyBar,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            '👋 Welcome, $_doctorName',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showCredentialsDrawer =
                                    !_showCredentialsDrawer;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Colors.white.withOpacity(0.1),
                            ),
                            icon: const Icon(Icons.settings_rounded, size: 15),
                            label: const Text(
                              'Account',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Sign Out',
                            onPressed: _logoutDoctor,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.danger.withOpacity(0.2),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 17),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: 'Academic Excuses '),
                        TextSpan(
                          text: 'Doctor Dashboard',
                          style: TextStyle(color: AppColors.gold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Review medical excuses and inspect full student attendance records.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Overlapping Filter Card
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDeep.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'University',
                              value: _selectedUni,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Beni-Suef University',
                                  child: Text('BSU (الحكومية)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Beni-Suef National University',
                                  child: Text('BSNU (الأهلية)'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedUni = v);
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Program',
                              value: _selectedProgram,
                              items: const [
                                DropdownMenuItem(
                                  value: 'General Program',
                                  child: Text('PharmD General'),
                                ),
                                DropdownMenuItem(
                                  value: 'Clinical Program',
                                  child: Text('PharmD Clinical'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedProgram = v);
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildDropdown(
                              label: 'Subject',
                              value: _selectedSubject,
                              items: AppColors.defaultSubjects
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedSubject = v);
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => _applyFilters(),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search ID/Name...',
                                prefixIcon:
                                    const Icon(Icons.search_rounded, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.bgSurface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(11),
                                  borderSide: const BorderSide(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Credentials Drawer
            if (_showCredentialsDrawer)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚙️ Update Your Login Credentials',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              controller: _newUserCtrl,
                              label: 'New Username',
                              hint: 'Username',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernTextField(
                              controller: _newPassCtrl,
                              label: 'New Password',
                              hint: 'Password',
                              icon: Icons.key_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _updateOwnCredentials,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text(
                            'Save Changes ✔',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      if (_credMessage != null && _credMessage!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _credMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _credSuccess
                                ? AppColors.emeraldDark
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Excuse Requests Selector & Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _filteredRequests.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 46,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No excuse requests match the current filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildExcuseReviewWorkspace(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcuseReviewWorkspace() {
    final student = _filteredRequests[_selectedStudentIndex];
    final List files = (student['files'] is List) ? student['files'] : [];
    final String currentImageUrl =
        (files.isNotEmpty && _selectedPhotoIndex < files.length)
            ? (files[_selectedPhotoIndex]['url'] ?? '').toString()
            : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal Student Selector Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const BoxDecoration(
            color: AppColors.emeraldDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Excuse Requests (${_filteredRequests.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                'Request ${_selectedStudentIndex + 1} of ${_filteredRequests.length}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              vertical: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            itemCount: _filteredRequests.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final item = _filteredRequests[idx];
              final isSelected = idx == _selectedStudentIndex;
              final stStatus = (item['status'] ?? 'Pending').toString();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStudentIndex = idx;
                    _selectedPhotoIndex = 0;
                    _statusActionMessage = null;
                  });
                  _loadAttendanceForSelectedStudent(item);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 210,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.emeraldSoft : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.emerald
                          : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${idx + 1}. ${item['name'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ID: ${item['studentId']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _buildStatusBadge(stStatus),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Main Excuse Image & Student Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(18)),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Medical Excuse Image Viewer
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (currentImageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: InteractiveViewer(
                          child: Image.network(
                            currentImageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.emeraldDark,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('Unable to load medical image'),
                            ),
                          ),
                        ),
                      )
                    else
                      const Text('No image attached'),
                    if (files.length > 1) ...[
                      Positioned(
                        left: 8,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setState(() {
                              _selectedPhotoIndex = (_selectedPhotoIndex -
                                      1 +
                                      files.length) %
                                  files.length;
                            });
                          },
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setState(() {
                              _selectedPhotoIndex =
                                  (_selectedPhotoIndex + 1) % files.length;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Image ${_selectedPhotoIndex + 1} of ${files.length}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (currentImageUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(currentImageUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text(
                        'Open Full Resolution',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 22),

              // Student Metadata
              Text(
                (student['name'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoLine('University', student['university']),
              _buildInfoLine('Program', student['program']),
              _buildInfoLine('Subject', student['subject']),
              _buildInfoLine('Student ID', student['studentId']),
              _buildInfoLine(
                'Excused Section',
                student['sectionRaw'],
                highlight: true,
              ),
              _buildInfoLine('Submission Date', student['timestamp']),
              _buildInfoLine(
                'Comment',
                (student['comment'] ?? '').toString().isEmpty
                    ? '—'
                    : student['comment'],
              ),
              _buildInfoLine('Current Status', student['status']),

              const SizedBox(height: 16),

              // Full Attendance Record Box
              _buildDoctorAttendanceCard(student),

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _changeExcuseStatus('Approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 19),
                      label: const Text(
                        'Approve (E)',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _changeExcuseStatus('Rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 19),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_statusActionMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusActionSuccess
                        ? AppColors.emeraldSoft
                        : AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusActionMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: _statusActionSuccess
                          ? AppColors.emeraldDark
                          : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorAttendanceCard(JsonMap student) {
    if (_loadingAttendanceRecord) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.emeraldSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final rec = _currentAttendanceRecord;
    if (rec == null || rec['found'] != true) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'Student Attendance Record Not Found in Subject Sheet.',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final stats = Map<String, dynamic>.from(rec['stats'] ?? {});
    final List sections = (rec['sections'] is List) ? rec['sections'] : [];
    final String targetSec = (student['sectionNumber'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Full Attendance (12 Sections)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF065F46),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Missed: ${stats['totalAbsence'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMiniStatCard(
                'Unexcused (A)',
                '${stats['unexcusedAbsence'] ?? 0}',
                AppColors.danger,
              ),
              const SizedBox(width: 8),
              _buildMiniStatCard(
                'Excused (E)',
                '${stats['excusedAbsence'] ?? 0}',
                AppColors.emerald,
              ),
              const SizedBox(width: 8),
              _buildMiniStatCard(
                'Score',
                '${stats['attendanceMarks'] ?? 5} / 5',
                AppColors.goldDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, i) {
              final s = sections[i];
              final secNum = (s['sectionNumber'] ?? '').toString();
              final raw = (s['rawStatus'] ?? '').toString();
              final isTarget = secNum == targetSec;

              Color badgeBg = AppColors.emeraldSoft;
              Color badgeFg = AppColors.emeraldDark;
              String label = 'P';
              if (raw == 'A') {
                badgeBg = AppColors.dangerSoft;
                badgeFg = AppColors.danger;
                label = 'A';
              } else if (raw == 'E') {
                badgeBg = const Color(0xFFD1FAE5);
                badgeFg = const Color(0xFF047857);
                label = 'E';
              }

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isTarget ? const Color(0xFFFEFCE8) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTarget ? AppColors.gold : AppColors.cardBorder,
                    width: isTarget ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sec $secNum',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      (s['sectionDate'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFD1FAE5)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. SUPER ADMIN NATIVE PORTAL (MASTER CONTROL + DOCTORS + AUDIT LOGS)
// ============================================================================
class SuperAdminNativePage extends StatefulWidget {
  final ValueChanged<bool> onLoginStateChanged;
  final void Function(bool loading, [String? msg]) onLoadingChanged;

  const SuperAdminNativePage({
    super.key,
    required this.onLoginStateChanged,
    required this.onLoadingChanged,
  });

  @override
  State<SuperAdminNativePage> createState() => SuperAdminNativePageState();
}

class SuperAdminNativePageState extends State<SuperAdminNativePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _masterUserCtrl = TextEditingController();
  final TextEditingController _masterPassCtrl = TextEditingController();

  final TextEditingController _docNameCtrl = TextEditingController();
  final TextEditingController _docUserCtrl = TextEditingController();
  final TextEditingController _docPassCtrl = TextEditingController();
  final TextEditingController _auditSearchCtrl = TextEditingController();

  bool _isLoggedIn = false;
  bool _obscurePass = true;
  String? _loginError;
  int _activeTab = 0; // 0 = Doctors Management, 1 = Audit Log

  String _savedMasterUser = '';
  String _savedMasterPass = '';

  List<JsonMap> _doctorsList = [];
  List<JsonMap> _auditLogs = [];
  String? _manageMsg;
  bool _manageSuccess = true;

  Future<void> refreshData() async {
    if (!_isLoggedIn) return;
    widget.onLoadingChanged(true, 'Refreshing Master Data...');
    final res = await PortalApiService.call('verifySuperAdminLogin', {
      'masterUser': _savedMasterUser,
      'masterPass': _savedMasterPass,
    });
    widget.onLoadingChanged(false);

    if (res['success'] == true) {
      setState(() {
        _doctorsList = List<JsonMap>.from(
          (res['doctors'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
        _auditLogs = List<JsonMap>.from(
          (res['auditLogs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
      });
    }
  }

  Future<void> _doSuperLogin() async {
    final u = _masterUserCtrl.text.trim();
    final p = _masterPassCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) {
      setState(() => _loginError = 'Enter Master Username and Password.');
      return;
    }

    setState(() => _loginError = null);
    widget.onLoadingChanged(true, 'Verifying Master Credentials...');

    final res = await PortalApiService.call('verifySuperAdminLogin', {
      'masterUser': u,
      'masterPass': p,
    });

    widget.onLoadingChanged(false);

    if (res['success'] == true) {
      setState(() {
        _isLoggedIn = true;
        _savedMasterUser = u;
        _savedMasterPass = p;
        _doctorsList = List<JsonMap>.from(
          (res['doctors'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
        _auditLogs = List<JsonMap>.from(
          (res['auditLogs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
      });
      widget.onLoginStateChanged(true);
    } else {
      setState(() {
        _loginError =
            (res['message'] ?? 'Access Denied: Invalid Super Admin credentials.')
                .toString();
      });
    }
  }

  void _logoutSuperAdmin() {
    setState(() {
      _isLoggedIn = false;
      _masterPassCtrl.clear();
      _doctorsList.clear();
      _auditLogs.clear();
    });
    widget.onLoginStateChanged(false);
  }

  Future<void> _saveDoctorAccount() async {
    final name = _docNameCtrl.text.trim();
    final user = _docUserCtrl.text.trim();
    final pass = _docPassCtrl.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    widget.onLoadingChanged(true, 'Saving Doctor Credentials...');
    final res = await PortalApiService.call('addDoctorAccountByMaster', {
      'masterUser': _savedMasterUser,
      'masterPass': _savedMasterPass,
      'doctorName': name,
      'username': user,
      'password': pass,
    });
    widget.onLoadingChanged(false);

    setState(() {
      _manageSuccess = res['success'] == true;
      _manageMsg = (res['message'] ?? '').toString();
      if (_manageSuccess) {
        _docNameCtrl.clear();
        _docUserCtrl.clear();
        _docPassCtrl.clear();
        _doctorsList = List<JsonMap>.from(
          (res['doctors'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
        _auditLogs = List<JsonMap>.from(
          (res['auditLogs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
      }
    });
  }

  Future<void> _deleteDoctor(int row) async {
    widget.onLoadingChanged(true, 'Removing Doctor Account...');
    final res = await PortalApiService.call('deleteDoctorAccountByMaster', {
      'masterUser': _savedMasterUser,
      'masterPass': _savedMasterPass,
      'row': row,
    });
    widget.onLoadingChanged(false);

    if (res['success'] == true) {
      setState(() {
        _doctorsList = List<JsonMap>.from(
          (res['doctors'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
        _auditLogs = List<JsonMap>.from(
          (res['auditLogs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isLoggedIn) {
      return _buildSuperLoginGate();
    }
    return _buildSuperControlCenter();
  }

  Widget _buildSuperLoginGate() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withOpacity(0.1),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      AppColors.deptLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_rounded,
                        size: 42,
                        color: AppColors.navyBar,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '🛡️ RESTRICTED MASTER ACCESS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.goldDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Super Admin Control',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage Doctor Credentials & Track Every System Action in Real Time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                _buildModernTextField(
                  controller: _masterUserCtrl,
                  label: 'Master Username',
                  hint: 'Enter Master Username',
                  icon: Icons.admin_panel_settings_outlined,
                ),
                const SizedBox(height: 14),
                _buildModernTextField(
                  controller: _masterPassCtrl,
                  label: 'Master Password',
                  hint: 'Enter Master Password',
                  icon: Icons.lock_person_outlined,
                  obscureText: _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  onSubmitted: (_) => _doSuperLogin(),
                ),
                if (_loginError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _loginError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _doSuperLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBar,
                      foregroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Unlock Super Admin →',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuperControlCenter() {
    final q = _auditSearchCtrl.text.trim().toLowerCase();
    final filteredLogs = _auditLogs.where((item) {
      if (q.isEmpty) return true;
      final str =
          '${item['doctorName']} ${item['username']} ${item['action']} ${item['target']} ${item['subjectInfo']} ${item['details']}'
              .toLowerCase();
      return str.contains(q);
    }).toList();

    return RefreshIndicator(
      color: AppColors.navyBar,
      onRefresh: refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 44),
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.5, -0.4),
                  radius: 1.4,
                  colors: [
                    AppColors.emeraldDark,
                    AppColors.navyBar,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🛡️ MASTER CONTROL CENTER',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _logoutSuperAdmin,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              AppColors.danger.withOpacity(0.25),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 15),
                        label: const Text(
                          'Lock',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Super Admin & Audit Log',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Assign or reset doctor credentials and inspect every action in real time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Segmented Tabs
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDeep.withOpacity(0.08),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 0
                                  ? AppColors.emeraldDark
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '👨‍🏫 Doctors (${_doctorsList.length})',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _activeTab == 0
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 1
                                  ? AppColors.emeraldDark
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '📋 Audit Log (${_auditLogs.length})',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _activeTab == 1
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_activeTab == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    // Add / Reset Doctor Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '➕ Assign / Reset Doctor Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildModernTextField(
                            controller: _docNameCtrl,
                            label: 'Doctor Full Name',
                            hint: 'e.g. Dr. Ahmed Hassan',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernTextField(
                                  controller: _docUserCtrl,
                                  label: 'Username',
                                  hint: 'ahmed.hassan',
                                  icon: Icons.alternate_email_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildModernTextField(
                                  controller: _docPassCtrl,
                                  label: 'Password',
                                  hint: 'Password',
                                  icon: Icons.password_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveDoctorAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Doctor Credentials ✔',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          if (_manageMsg != null && _manageMsg!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _manageMsg!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _manageSuccess
                                    ? AppColors.emeraldDark
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Doctors List
                    ..._doctorsList.map(
                      (d) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (d['doctorName'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '@${d['username']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.goldSoft,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'Pass: ${d['password']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.goldDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _deleteDoctor(int.tryParse('${d['row']}') ?? 0),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    TextField(
                      controller: _auditSearchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Search audit log by doctor, student, action...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...filteredLogs.map(
                      (log) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${log['doctorName']} (@${log['username']})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  (log['timestamp'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${log['action']} • ${log['target']}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${log['subjectInfo']} — ${log['details']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
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

// ============================================================================
// 3. STUDENT ATTENDANCE & EXCUSES NATIVE SCREEN (SWIPEABLE BSNU / BSU + UPLOAD)
// ============================================================================
class StudentPortalNativeScreen extends StatefulWidget {
  const StudentPortalNativeScreen({super.key});

  @override
  State<StudentPortalNativeScreen> createState() =>
      _StudentPortalNativeScreenState();
}

class _StudentPortalNativeScreenState extends State<StudentPortalNativeScreen> {
  final PageController _uniPageController = PageController(initialPage: 0);
  final TextEditingController _studentIdCtrl = TextEditingController();
  final TextEditingController _commentCtrl = TextEditingController();

  bool _isLoading = false;
  String? _loadingLabel;
  bool _showInstructions = false;

  int _uniIndex = 0; // 0 = BSNU (الأهلية), 1 = BSU (الحكومية)
  String _selectedProgram = 'Clinical Program';
  String _selectedSubject = AppColors.defaultSubjects.first;

  JsonMap? _attendanceResult;

  // Excuse submission state
  int? _excuseSectionNumber;
  String? _excuseSectionDate;
  final List<XFile> _pickedImages = [];

  String get _currentUniversityName => _uniIndex == 0
      ? 'Beni-Suef National University'
      : 'Beni-Suef University';

  void _setLoading(bool val, [String? label]) {
    if (!mounted) return;
    setState(() {
      _isLoading = val;
      _loadingLabel = label;
    });
  }

  void _switchUniversity(int index) {
    setState(() {
      _uniIndex = index;
      _attendanceResult = null;
      _excuseSectionNumber = null;
    });
    _uniPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _checkAttendance() async {
    final code = _studentIdCtrl.text.trim();
    if (code.isEmpty) {
      _showDialogMessage('⚠️ Student ID Required', 'Please enter your student code.');
      return;
    }

    _setLoading(true, 'Checking Attendance Record...');
    final res = await PortalApiService.call('getStudentFullRecord', {
      'university': _currentUniversityName,
      'program': _selectedProgram,
      'subject': _selectedSubject,
      'studentId': code,
    });
    _setLoading(false);

    if (res['found'] == true) {
      setState(() {
        _attendanceResult = res;
        _excuseSectionNumber = null;
      });
    } else {
      _showDialogMessage(
        '⚠️ Record Not Found',
        (res['error'] ?? 'Student code not found in this subject.').toString(),
      );
    }
  }

  Future<void> _pickExcuseImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 82);
    if (files.isNotEmpty) {
      setState(() {
        _pickedImages
          ..clear()
          ..addAll(files);
      });
    }
  }

  Future<void> _submitMedicalExcuse() async {
    if (_attendanceResult == null || _excuseSectionNumber == null) return;
    if (_pickedImages.isEmpty) {
      _showDialogMessage(
        '⚠️ Image Required',
        'Please select at least one medical excuse image.',
      );
      return;
    }

    _setLoading(true, 'Uploading Medical Excuse...');

    final List<JsonMap> encodedFiles = [];
    for (final img in _pickedImages) {
      final bytes = await img.readAsBytes();
      encodedFiles.add({
        'filename': img.name,
        'mimeType': 'image/jpeg',
        'base64': base64Encode(bytes),
      });
    }

    final res = await PortalApiService.call('uploadFile', {
      'university': _currentUniversityName,
      'program': _selectedProgram,
      'subject': _selectedSubject,
      'name': _attendanceResult!['studentName'],
      'studentId': _attendanceResult!['studentId'],
      'section': '$_excuseSectionNumber',
      'sectionDate': _excuseSectionDate ?? '',
      'comment': _commentCtrl.text.trim(),
      'files': encodedFiles,
    });

    _setLoading(false);

    if (res['success'] == true) {
      setState(() {
        _excuseSectionNumber = null;
        _pickedImages.clear();
        _commentCtrl.clear();
      });
      await _checkAttendance();
      _showDialogMessage(
        '✅ Submitted Successfully',
        (res['message'] ?? 'Excuse request submitted for review.').toString(),
      );
    } else {
      _showDialogMessage(
        '⚠️ Submission Notice',
        (res['message'] ?? 'Could not submit excuse request.').toString(),
      );
    }
  }

  void _showDialogMessage(String title, String body) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        content: Text(body, style: const TextStyle(fontSize: 13.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navyBar,
        foregroundColor: Colors.white,
        title: const Text(
          '👨‍🎓 Student Attendance & Excuses Portal',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                setState(() => _showInstructions = !_showInstructions),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            icon: const Icon(Icons.menu_book_rounded, size: 16),
            label: const Text(
              'تعليمات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Section
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 52),
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.5, -0.3),
                      radius: 1.4,
                      colors: [
                        Color(0xFF0F4C42),
                        AppColors.emeraldMid,
                        AppColors.navyBar,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.4),
                          ),
                        ),
                        child: const Text(
                          '● OFFICIAL ACADEMIC & STUDENT PORTAL',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(text: 'Understanding Microbes,\n'),
                            TextSpan(
                              text: 'Strengthening ',
                              style: TextStyle(color: AppColors.gold),
                            ),
                            TextSpan(
                              text: 'Health.',
                              style: TextStyle(color: AppColors.emeraldLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Card
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navyDeep.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showInstructions) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  '📋 تعليمات هامة للطلاب:\n'
                                  '١. الطالب المتغيب عن امتحان كويز أو عملي بدون عذر يقبله مجلس القسم لن يعاد له الامتحان.\n'
                                  '٢. الغياب عن السكاشن بدون عذر يعتبر غياباً محسوباً، وبعذر يتم اعتماد الغياب ولا يحاسب عليه الطالب من حيث الدرجات ولكن يُعد من ضمن نسبة الـ ٢٥٪.\n'
                                  '٣. لا يُعتد بعذر أي طالب إلا بعذر طبي معتمد.\n'
                                  '٤. أعذار الامتحانات تكون قبل الامتحان وليس بعده وتقدم المستندات خلال ٣ أيام.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.65,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const Text(
                            'STEP 1: SWIPE OR TAP TO SELECT UNIVERSITY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Swipeable Mega University Cards
                          SizedBox(
                            height: 148,
                            child: PageView(
                              controller: _uniPageController,
                              onPageChanged: (idx) {
                                setState(() {
                                  _uniIndex = idx;
                                  _attendanceResult = null;
                                  _excuseSectionNumber = null;
                                });
                              },
                              children: [
                                _buildUniversityCard(
                                  code: 'BSNU',
                                  title: 'Faculty of Pharmacy — BSNU',
                                  arabicTitle:
                                      'كلية الصيدلة — جامعة بني سويف الأهلية',
                                  logoUrl: AppColors.bsnuLogo,
                                  primaryColor: AppColors.bsnuBlue,
                                  bgColor: AppColors.bsnuSoft,
                                ),
                                _buildUniversityCard(
                                  code: 'BSU',
                                  title: 'Faculty of Pharmacy — BSU',
                                  arabicTitle:
                                      'كلية الصيدلة — جامعة بني سويف الحكومية',
                                  logoUrl: AppColors.bsuLogo,
                                  primaryColor: AppColors.goldDark,
                                  bgColor: AppColors.goldSoft,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _switchUniversity(0),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _uniIndex == 0
                                        ? AppColors.navyBar
                                        : AppColors.bgSurface,
                                    foregroundColor: _uniIndex == 0
                                        ? AppColors.gold
                                        : AppColors.textMuted,
                                  ),
                                  child: const Text(
                                    '● BSNU (الأهلية)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _switchUniversity(1),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _uniIndex == 1
                                        ? AppColors.navyBar
                                        : AppColors.bgSurface,
                                    foregroundColor: _uniIndex == 1
                                        ? AppColors.gold
                                        : AppColors.textMuted,
                                  ),
                                  child: const Text(
                                    '● BSU (الحكومية)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Text(
                            'STEP 2: SELECT PROGRAM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildProgramCard(
                                  title: 'PharmD Clinical',
                                  arabic: 'الصيدلة الإكلينيكية',
                                  icon: Icons.medical_services_rounded,
                                  selected:
                                      _selectedProgram == 'Clinical Program',
                                  onTap: () => setState(
                                    () =>
                                        _selectedProgram = 'Clinical Program',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildProgramCard(
                                  title: 'PharmD General',
                                  arabic: 'الصيدلة العام',
                                  icon: Icons.science_rounded,
                                  selected:
                                      _selectedProgram == 'General Program',
                                  onTap: () => setState(
                                    () => _selectedProgram = 'General Program',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          _buildDropdown(
                            label: 'STEP 3: Choose Subject',
                            value: _selectedSubject,
                            items: AppColors.defaultSubjects
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedSubject = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildModernTextField(
                            controller: _studentIdCtrl,
                            label: 'STEP 4: Student ID / Code',
                            hint: 'Enter your Code (e.g. 240001)',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => _checkAttendance(),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _checkAttendance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: const Color(0xFF111827),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Check Attendance Record ▾',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                          if (_attendanceResult != null) ...[
                            const SizedBox(height: 22),
                            _buildStudentResultSection(_attendanceResult!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          TopFloatingCircularLoader(
            isLoading: _isLoading,
            label: _loadingLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildUniversityCard({
    required String code,
    required String title,
    required String arabicTitle,
    required String logoUrl,
    required Color primaryColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: primaryColor, width: 2.5),
            ),
            child: ClipOval(
              child: Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.account_balance_rounded, color: primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '✔ ACTIVE PORTAL • $code',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  arabicTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard({
    required String title,
    required String arabic,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FDF9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.cardBorder,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.emeraldDark : AppColors.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            Text(
              arabic,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentResultSection(JsonMap res) {
    final stats = Map<String, dynamic>.from(res['stats'] ?? {});
    final List allSecs = (res['sections'] is List) ? res['sections'] : [];
    final absentSecs = allSecs
        .where((s) => s['rawStatus'] == 'A' || s['rawStatus'] == 'E')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.emeraldDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (res['studentName'] ?? '').toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${res['studentId']} • ${res['subject']}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatBox(
              'Excused (E)',
              '${stats['excusedAbsence'] ?? 0}',
              AppColors.emerald,
            ),
            const SizedBox(width: 6),
            _buildStatBox(
              'Unexcused (A)',
              '${stats['unexcusedAbsence'] ?? 0}',
              AppColors.danger,
            ),
            const SizedBox(width: 6),
            _buildStatBox(
              'Marks',
              '${stats['attendanceMarks'] ?? 5}',
              AppColors.goldDark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (absentSecs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '🎉 منتظم في الحضور — لا توجد أي سكاشن غياب مسجلة عليك في هذه المادة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.emeraldDark,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          )
        else
          ...absentSecs.map((sec) {
            final secNum = int.tryParse('${sec['sectionNumber']}') ?? 0;
            final secDate = (sec['sectionDate'] ?? '').toString();
            final raw = (sec['rawStatus'] ?? '').toString();
            final excuse = sec['excuse'] is Map ? sec['excuse'] as Map : null;
            final exStatus = excuse != null ? '${excuse['status']}' : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section $secNum ($secDate)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        raw == 'E'
                            ? 'Excused (E) ✔'
                            : (exStatus.isNotEmpty
                                ? 'Excuse: $exStatus'
                                : 'Absent (A)'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: raw == 'E'
                              ? AppColors.emeraldDark
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  if (raw == 'A' && exStatus.isEmpty)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _excuseSectionNumber = secNum;
                          _excuseSectionDate = secDate;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Submit Excuse',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

        // Excuse Upload Drawer
        if (_excuseSectionNumber != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Submit Medical Excuse — Section $_excuseSectionNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.goldDark,
                  ),
                ),
                const SizedBox(height: 10),
                _buildModernTextField(
                  controller: _commentCtrl,
                  label: 'Comment / Reason (Optional)',
                  hint: 'Write any note for the doctor...',
                  icon: Icons.notes_rounded,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickExcuseImages,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(
                    _pickedImages.isEmpty
                        ? 'Choose Medical Excuse Photos'
                        : 'Selected ${_pickedImages.length} photo(s)',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _submitMedicalExcuse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldDark,
                    foregroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Submit Excuse Request →',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatBox(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED UI HELPERS
// ============================================================================
Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  bool obscureText = false,
  Widget? suffixIcon,
  TextInputType? keyboardType,
  ValueChanged<String>? onSubmitted,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF334155),
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 19, color: AppColors.textMuted),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.bgSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.emerald, width: 1.8),
          ),
        ),
      ),
    ],
  );
}

Widget _buildDropdown({
  required String label,
  required String value,
  required List<StringMenuItem> items,
  required ValueChanged<String?> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF334155),
        ),
      ),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.bgSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      ),
    ],
  );
}

Widget _buildStatusBadge(String status) {
  Color bg = AppColors.goldSoft;
  Color fg = AppColors.goldDark;
  if (status == 'Approved') {
    bg = const Color(0xFFD1FAE5);
    fg = const Color(0xFF065F46);
  } else if (status == 'Rejected') {
    bg = AppColors.dangerSoft;
    fg = AppColors.danger;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg),
    ),
  );
}

Widget _buildInfoLine(String label, dynamic value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.5),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          TextSpan(
            text: '${value ?? '—'}',
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
              color: highlight ? AppColors.emeraldDark : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    ),
  );
}
