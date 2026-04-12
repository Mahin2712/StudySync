import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'room_sheet.dart';
import 'leaderboard_screen.dart';
import 'stats_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  bool _isSidebarExpanded = true;

  String get _userEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? 'Studier';

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  // ─── Colors (from prototype) ───────────────────────────────────────────────
  static const _bg = Color(0xFF0C0E11);
  static const _surface = Color(0xFF111417);
  static const _surfaceHigh = Color(0xFF1C2025);
  static const _surfaceHighest = Color(0xFF22262C);
  static const _primary = Color(0xFFADCBDB);
  static const _primaryContainer = Color(0xFF395664);
  static const _onPrimaryContainer = Color(0xFFC9E8F8);
  // _tertiary = Color(0xFFD3DCFF) — reserved for future accent use
  static const _onSurface = Color(0xFFE2E5EE);
  static const _onSurfaceVariant = Color(0xFFA7ABB3);
  static const _outline = Color(0xFF72767D);
  static const _outlineVariant = Color(0xFF44484F);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Radial background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF171A1E), _bg],
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildTopAppBar(),
              Expanded(
                child: Row(
                  children: [
                    // Left sidebar
                    if (!isNarrow || _isSidebarExpanded)
                      _buildLeftSidebar(isNarrow),

                    // Main canvas
                    Expanded(child: _buildMainCanvas()),

                    // Right panel
                    if (!isNarrow) _buildRightPanel(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Top App Bar ───────────────────────────────────────────────────────────
  Widget _buildTopAppBar() {
    return Container(
      height: 64,
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Brand
          const Text(
            'StudySync',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 16),

          // Room pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF171A1E),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _outline,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Quantum Physics Room • 0 Studiers',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Nav links
          _navLink('Profile'),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const LeaderboardScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
            child: const Text(
              'Leaderboard',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: _primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const StatsDashboardScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
            child: const Text(
              'My Stats',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: _primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 24),
          _navLink('Settings'),
          const SizedBox(width: 20),

          // Icon buttons
          _iconBtn(Icons.group_outlined),
          const SizedBox(width: 4),
          _iconBtn(Icons.notifications_outlined),
          const SizedBox(width: 12),

          // Avatar + sign out
          GestureDetector(
            onTap: () => _showSignOutDialog(),
            child: Tooltip(
              message: 'Sign out (${_userEmail})',
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceHighest,
                  border: Border.all(
                    color: _outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: _onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: _primary, size: 22),
      padding: const EdgeInsets.all(6),
    );
  }

  // ─── Left Sidebar ──────────────────────────────────────────────────────────
  Widget _buildLeftSidebar(bool isNarrow) {
    return Container(
      width: 240,
      color: _surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF171A1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.meeting_room_outlined,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Controls',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                  Text(
                    'DEEP WORK PHASE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      color: _onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Nav items
          _sidebarItem(
            icon: Icons.play_circle_outline_rounded,
            label: 'Start Session',
            active: true,
          ),
          _sidebarItem(
            icon: Icons.timer_outlined,
            label: 'Timer',
            disabled: true,
          ),
          _sidebarItem(
            icon: Icons.how_to_reg_outlined,
            label: 'Check-in',
            disabled: true,
          ),
          _sidebarItem(
            icon: Icons.info_outline_rounded,
            label: 'Session Info',
            disabled: true,
          ),

          const Spacer(),

          // Join Table button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => RoomSheet.show(context),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Join Table'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryContainer,
                foregroundColor: _onPrimaryContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    bool active = false,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF171A1E) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: active ? _primary : _onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? _primary : _onSurfaceVariant,
            ),
          ),
          onTap: disabled ? null : () {},
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ─── Main Canvas (Study Table) ─────────────────────────────────────────────
  Widget _buildMainCanvas() {
    return Stack(
      children: [
        // Atmospheric glow
        Center(
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 500 * _glowAnim.value,
              height: 500 * _glowAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primary.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        Center(
          child: SizedBox(
            width: 520,
            height: 520,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Table shadow
                Positioned(
                  top: 20,
                  child: Container(
                    width: 460,
                    height: 460,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Table top
                Container(
                  width: 460,
                  height: 460,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1C2025),
                        Color(0xFF111417),
                      ],
                    ),
                    border: Border.all(
                      color: _outlineVariant.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        // Dot grid texture
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DotGridPainter(),
                          ),
                        ),
                        // Inner ring content
                        Center(
                          child: Container(
                            width: 380,
                            height: 380,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _primary.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _surfaceHighest,
                                    border: Border.all(
                                      color: _outlineVariant.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chair_alt_rounded,
                                    color: _primary,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'The room is quiet.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: _onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 48),
                                  child: Text(
                                    'Ready to start your focused study session? Be the first to take a seat.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: _onSurfaceVariant,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                ElevatedButton(
                                  onPressed: () => RoomSheet.show(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryContainer,
                                    foregroundColor: _onPrimaryContainer,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 14),
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  child: const Text('Start Studying'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Seat placeholders around the table
                ..._buildSeatPlaceholders(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSeatPlaceholders() {
    const positions = [
      Alignment(0, -1.1),   // top
      Alignment(1.1, -0.5), // top-right
      Alignment(1.1, 0.5),  // bottom-right
      Alignment(0, 1.1),    // bottom
      Alignment(-1.1, 0.5), // bottom-left
      Alignment(-1.1, -0.5),// top-left
    ];

    return positions.map((align) {
      return Align(
        alignment: align,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _outlineVariant.withOpacity(0.35),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: _outlineVariant,
            size: 18,
          ),
        ),
      );
    }).toList();
  }

  // ─── Right Panel ───────────────────────────────────────────────────────────
  Widget _buildRightPanel() {
    return Container(
      width: 288,
      decoration: const BoxDecoration(
        color: Color(0xFF111417),
        border: Border(
          left: BorderSide(color: Color(0x26A7ABB3), width: 1),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Peers header
                  const Text(
                    'COLLABORATION',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Active Peers',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Join the table to see who is studying.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: _onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Leaderboard section
                  Row(
                    children: const [
                      Icon(Icons.leaderboard_outlined,
                          color: _onSurfaceVariant, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'LEADERBOARD',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surfaceHigh.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _outlineVariant.withOpacity(0.12),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            color: _outlineVariant, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'No active leaderboard yet.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: _onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Chat section
                  Row(
                    children: const [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: _onSurfaceVariant, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'MINIMAL CHAT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _surfaceHigh.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _outlineVariant.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _surfaceHighest,
                          ),
                          child: const Icon(Icons.forum_outlined,
                              color: Color(0x80ADCBDB), size: 20),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Be the first to join the chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Share resources, ask questions,\nor just send a focused hello.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: _outline,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Disabled chat input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x1AA7ABB3)),
              ),
            ),
            child: Opacity(
              opacity: 0.4,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _surfaceHighest,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Join the room to chat...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.send_rounded, color: _primary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171A1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
              fontFamily: 'Inter', color: _onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Signed in as $_userEmail\n\nAre you sure you want to sign out?',
          style: const TextStyle(
              fontFamily: 'Inter', color: _onSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryContainer,
              foregroundColor: _onPrimaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Dot Grid Painter ──────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = const Color(0xFFADCBDB).withOpacity(0.06)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
