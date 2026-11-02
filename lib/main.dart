import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MicroDeptFlutterApp());
}

/// ضع رابط الـ Web App الذي نسخته من Google Apps Script هنا (الذي ينتهي بـ /exec)
const String kBaseWebAppUrl =
    'https://script.google.com/macros/s/AKfycbygFGReaYRWp4gZqhjkc7iTbJXhfxC3rq5-w_qhYxcq9UCgfFQlOUOvC7MPf7En-FnG4A/exec';

class MicroDeptFlutterApp extends StatelessWidget {
  const MicroDeptFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microbiology & Immunology Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B4A40),
          primary: const Color(0xFF161B29),
          secondary: const Color(0xFFF5B82E),
        ),
      ),
      home: const MainAdminSuperShell(),
    );
  }
}

class MainAdminSuperShell extends StatefulWidget {
  const MainAdminSuperShell({super.key});

  @override
  State<MainAdminSuperShell> createState() => _MainAdminSuperShellState();
}

class _MainAdminSuperShellState extends State<MainAdminSuperShell> {
  final PageController _pageController = PageController(initialPage: 0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentPageIndex = 0; // 0 = Admin (Doctor), 1 = Super Admin

  // مفاتيح للتحكم في إعادة تحميل الصفحات عند الحاجة
  final GlobalKey<_PortalWebViewKeepAliveState> _adminWebKey = GlobalKey();
  final GlobalKey<_PortalWebViewKeepAliveState> _superAdminWebKey = GlobalKey();

  String get _adminUrl => '$kBaseWebAppUrl?page=admin';
  String get _superAdminUrl => '$kBaseWebAppUrl?page=superadmin';
  String get _studentUrl => kBaseWebAppUrl;

  void _animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _openStudentPortalModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentPortalScreen(studentUrl: _studentUrl),
      ),
    );
  }

  void _reloadCurrentWebView() {
    if (_currentPageIndex == 0) {
      _adminWebKey.currentState?.reload();
    } else {
      _superAdminWebKey.currentState?.reload();
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
      // قائمة جانبية للتنقل السريع أيضاً
      drawer: _buildNavigationDrawer(isSuperAdmin),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B29),
        foregroundColor: Colors.white,
        elevation: 3,
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSuperAdmin
                    ? const Color(0xFFF5B82E).withOpacity(0.18)
                    : const Color(0xFF10B981).withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSuperAdmin
                      ? const Color(0xFFF5B82E)
                      : const Color(0xFF10B981),
                ),
              ),
              child: Text(
                isSuperAdmin ? '🛡️ Super Admin' : '👨‍🏫 Doctor Admin',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSuperAdmin
                      ? const Color(0xFFF5B82E)
                      : const Color(0xFF34D399),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Microbiology & Immunology',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // زر إعادة تحميل الصفحة الحالية
          IconButton(
            tooltip: 'تحديث الصفحة',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            onPressed: _reloadCurrentWebView,
          ),
          // الزر الصغير في أعلى اليمين لفتح بوابة الطالب (Student Portal)
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 4),
            child: ElevatedButton.icon(
              onPressed: _openStudentPortalModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5B82E),
                foregroundColor: const Color(0xFF111827),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.school_rounded, size: 15),
              label: const Text(
                'Student Portal',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        // شريط علوي صغير يوضح حالة الـ Sliding بين Admin و Super Admin
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _animateToPage(0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: !isSuperAdmin
                            ? const Color(0xFF0B4A40)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '👨‍🏫 Admin (Doctor Portal)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: !isSuperAdmin
                              ? const Color(0xFFF5B82E)
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _animateToPage(1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isSuperAdmin
                            ? const Color(0xFF0B4A40)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '🛡️ Super Admin (Master)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isSuperAdmin
                              ? const Color(0xFFF5B82E)
                              : Colors.white60,
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
      body: Stack(
        children: [
          // PageView يدعم السحب الأفقي (Sliding) للتحويل بين Admin و Super Admin
          PageView(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() {
                _currentPageIndex = idx;
              });
            },
            children: [
              // الصفحة الأولى (الافتراضية): Admin (Doctor Portal)
              PortalWebViewKeepAlive(
                key: _adminWebKey,
                initialUrl: _adminUrl,
                onOpenStudentPortal: _openStudentPortalModal,
                onSwitchToAdmin: () => _animateToPage(0),
                onSwitchToSuperAdmin: () => _animateToPage(1),
              ),
              // الصفحة الثانية (عند عمل Sliding): Super Admin
              PortalWebViewKeepAlive(
                key: _superAdminWebKey,
                initialUrl: _superAdminUrl,
                onOpenStudentPortal: _openStudentPortalModal,
                onSwitchToAdmin: () => _animateToPage(0),
                onSwitchToSuperAdmin: () => _animateToPage(1),
              ),
            ],
          ),

          // زر جانبي عائم (Side Handle Button) على حافة الشاشة للتبديل بضغطة واحدة أو السحب
          Positioned(
            right: isSuperAdmin ? null : 0,
            left: isSuperAdmin ? 0 : null,
            top: MediaQuery.of(context).size.height * 0.42,
            child: GestureDetector(
              onTap: () => _animateToPage(isSuperAdmin ? 0 : 1),
              onHorizontalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < -150 && !isSuperAdmin) {
                  _animateToPage(1);
                } else if ((details.primaryVelocity ?? 0) > 150 && isSuperAdmin) {
                  _animateToPage(0);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B29).withOpacity(0.92),
                  borderRadius: BorderRadius.horizontal(
                    left: isSuperAdmin ? Radius.zero : const Radius.circular(14),
                    right: isSuperAdmin ? const Radius.circular(14) : Radius.zero,
                  ),
                  border: Border.all(color: const Color(0xFFF5B82E), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
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
                      color: const Color(0xFFF5B82E),
                      size: 16,
                    ),
                    const SizedBox(height: 6),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        isSuperAdmin ? 'ADMIN' : 'SUPER ADMIN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(bool isSuperAdmin) {
    return Drawer(
      backgroundColor: const Color(0xFF161B29),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0B4A40),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF5B82E), width: 1.5),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MICROBIOLOGY & IMMUNOLOGY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Faculty of Pharmacy • BSU & BSNU',
                    style: TextStyle(
                      color: Color(0xFFF5B82E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              selected: !isSuperAdmin,
              selectedTileColor: Colors.white10,
              leading: const Icon(Icons.medical_information_rounded,
                  color: Color(0xFF34D399)),
              title: const Text(
                'Doctor Admin Portal (الرئيسية)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'مراجعة الأعذار الطبية وغياب الطلاب',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _animateToPage(0);
              },
            ),
            ListTile(
              selected: isSuperAdmin,
              selectedTileColor: Colors.white10,
              leading:
                  const Icon(Icons.admin_panel_settings, color: Color(0xFFF5B82E)),
              title: const Text(
                'Super Admin Control',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'إدارة حسابات الدكاترة والمواد وسجل التعديلات',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _animateToPage(1);
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.school_rounded, color: Colors.amberAccent),
              title: const Text(
                'Student Portal (بوابة الطلاب)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
          ],
        ),
      ),
    );
  }
}

/// شاشة مستقلة لبوابة الطالب تفتح عند الضغط على زر Student Portal في أعلى اليمين
class StudentPortalScreen extends StatefulWidget {
  final String studentUrl;

  const StudentPortalScreen({super.key, required this.studentUrl});

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  final GlobalKey<_PortalWebViewKeepAliveState> _studentWebKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4A40),
        foregroundColor: Colors.white,
        title: const Text(
          '👨‍🎓 Student Attendance & Excuses Portal',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _studentWebKey.currentState?.reload(),
          ),
        ],
      ),
      body: PortalWebViewKeepAlive(
        key: _studentWebKey,
        initialUrl: widget.studentUrl,
        onOpenStudentPortal: () {},
        onSwitchToAdmin: () => Navigator.of(context).pop(),
        onSwitchToSuperAdmin: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// ودجت الـ WebView مع الاحتفاظ بالحالة (AutomaticKeepAliveClientMixin)
/// حتى لا يفقد الدكتور تسجيل الدخول عند عمل Sliding بين Admin و Super Admin
class PortalWebViewKeepAlive extends StatefulWidget {
  final String initialUrl;
  final VoidCallback onOpenStudentPortal;
  final VoidCallback onSwitchToAdmin;
  final VoidCallback onSwitchToSuperAdmin;

  const PortalWebViewKeepAlive({
    super.key,
    required this.initialUrl,
    required this.onOpenStudentPortal,
    required this.onSwitchToAdmin,
    required this.onSwitchToSuperAdmin,
  });

  @override
  State<PortalWebViewKeepAlive> createState() => _PortalWebViewKeepAliveState();
}

class _PortalWebViewKeepAliveState extends State<PortalWebViewKeepAlive>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _webViewController;
  double _progress = 0;

  @override
  bool get wantKeepAlive => true;

  void reload() {
    _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            allowFileAccess: true,
            allowContentAccess: true,
            supportZoom: false,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            thirdPartyCookiesEnabled: true,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
          // التقاط الروابط الداخلية في صفحات HTML وتحويلها إلى تنقل سلس داخل التطبيق
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final uri = navigationAction.request.url;
            if (uri == null) return NavigationActionPolicy.ALLOW;
            final urlStr = uri.toString();

            if (urlStr.contains('page=superadmin')) {
              widget.onSwitchToSuperAdmin();
              return NavigationActionPolicy.Cancel;
            }
            if (urlStr.contains('page=admin')) {
              widget.onSwitchToAdmin();
              return NavigationActionPolicy.Cancel;
            }
            if (urlStr.endsWith('?') || urlStr == kBaseWebAppUrl) {
              widget.onOpenStudentPortal();
              return NavigationActionPolicy.Cancel;
            }
            return NavigationActionPolicy.ALLOW;
          },
        ),
        if (_progress < 1.0)
          LinearProgressIndicator(
            value: _progress,
            minHeight: 3,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5B82E)),
          ),
      ],
    );
  }
}
