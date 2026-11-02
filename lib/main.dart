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
  static Future> call(
    String action, [
    Map<String, dynamic>? payload,
  ]) async {
    final Map<String, dynamic> bodyData = {
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

  static Map<String, dynamic> _decodeSafe(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
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
                  color: AppColors.gold.withValues(alpha: 0.65),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.18),
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
                    ? AppColors.gold.withValues(alpha: 0.16)
                    : AppColors.emerald.withValues(alpha: 0.18),
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
                        ? AppColors.emeraldLight.withValues(alpha: 0.7)
                        : AppColors.gold.withValues(alpha: 0.8),
                    width: 1.3,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
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
                                    ? AppColors.emerald.withValues(alpha: 0.5)
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
                                    ? AppColors.gold.withValues(alpha: 0.5)
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
                    color: AppColors.navyBar.withValues(alpha: 0.94),
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

  List> _allExcuseRequests = [];
  List> _filteredRequests = [];
  int _selectedStudentIndex = 0;
  int _selectedPhotoIndex = 0;

  Map<String, dynamic>? _currentAttendanceRecord;
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
    final res = await Portal
