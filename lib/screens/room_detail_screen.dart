import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_session_model.dart';
import '../services/room_service.dart';
import '../services/session_service.dart';

/// Screen shown once a user has joined/created a room.
class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ───────────────────────────────────────────────────────────────
  List<String> _memberIds = [];
  bool _isLoading = true;
  bool _isStarting = false; // prevents double-tap

  StudySessionModel? _mySession; // null = not studying
  List<StudySessionModel> _activeSessions = [];

  Timer? _uiTicker;          // ticks every second
  Timer? _pollTimer;         // polls DB every 5 s
  Timer? _checkinGraceTimer; // fires auto-stop if check-in ignored
  bool _checkinPopupShowing = false;
  // uid → time they disappeared (shows 🔴 for 5 s)
  final Map<String, DateTime> _recentlyMissedUserIds = {};

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // ─── Colors ─────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0C0E11);
  static const _surface = Color(0xFF111417);
  static const _surfaceHigh = Color(0xFF1C2025);
  static const _surfaceHighest = Color(0xFF22262C);
  static const _primary = Color(0xFFADCBDB);
  static const _primaryContainer = Color(0xFF395664);
  static const _onPrimaryContainer = Color(0xFFC9E8F8);
  static const _onSurface = Color(0xFFE2E5EE);
  static const _onSurfaceVariant = Color(0xFFA7ABB3);
  static const _outline = Color(0xFF44484F);
  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFFF6B6B);
  static const _amber = Color(0xFFFFB74D);

  String get _myUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  bool get _isStudying => _mySession != null;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _initialLoad();
    _startUiTicker();
    _startPollTimer();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _uiTicker?.cancel();
    _pollTimer?.cancel();
    _checkinGraceTimer?.cancel();
    super.dispose();
  }

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> _initialLoad() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadMembers(),
      _loadSessionState(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMembers() async {
    try {
      final ids = await RoomService.getRoomMembers(widget.roomId);
      if (mounted) setState(() => _memberIds = ids);
    } catch (_) {}
  }

  Future<void> _loadSessionState() async {
    try {
      final my = await SessionService.getActiveSessionForUser();
      final all = await SessionService.getActiveSessions(widget.roomId);
      if (mounted) {
        // Detect users who just went offline → show 🔴 for 5 s
        final oldIds = _activeSessions.map((s) => s.userId).toSet();
        final newIds = all.map((s) => s.userId).toSet();
        final now = DateTime.now();
        for (final uid in oldIds.difference(newIds)) {
          if (uid != _myUserId) _recentlyMissedUserIds[uid] = now;
        }
        setState(() {
          _mySession = my;
          _activeSessions = all;
        });
      }
    } catch (_) {}
  }

  void _startUiTicker() {
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // ── Check-in trigger (only MY session) ───────────────────────────────
      if (_mySession != null && !_checkinPopupShowing) {
        final next = _mySession!.nextCheckinAt;
        if (next != null && DateTime.now().toUtc().isAfter(next)) {
          _showCheckinPopup();
        }
      }
      // ── Expire recently-missed linger after 5 s ──────────────────────────
      final now = DateTime.now();
      _recentlyMissedUserIds
          .removeWhere((_, t) => now.difference(t).inSeconds >= 5);
      // ── Rebuild UI ────────────────────────────────────────────────────────
      if (_activeSessions.isNotEmpty ||
          _recentlyMissedUserIds.isNotEmpty ||
          _mySession != null) {
        setState(() {});
      }
    });
  }

  void _startPollTimer() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _loadSessionState();
    });
  }

  // ─── Session actions ──────────────────────────────────────────────────────

  Future<void> _startStudying({String? subject}) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    try {
      final session = await SessionService.startSession(
        widget.roomId,
        subject: subject,
      );
      if (mounted) {
        setState(() => _mySession = session);
        await _loadSessionState(); // refresh others' sessions too
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start session: $e'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _stopStudying() async {
    try {
      await SessionService.stopSession();
      if (mounted) {
        setState(() => _mySession = null);
        await _loadSessionState();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not stop session: $e'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

  void _showStartDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171A1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Start Studying',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What are you studying? (optional)",
              style: TextStyle(fontFamily: 'Inter', color: _onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontFamily: 'Inter', color: _onSurface),
              decoration: InputDecoration(
                hintText: 'e.g. Physics Chapter 5…',
                hintStyle: const TextStyle(color: _onSurfaceVariant, fontFamily: 'Inter'),
                filled: true,
                fillColor: _surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Inter', color: _onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              final subject =
                  controller.text.trim().isEmpty ? null : controller.text.trim();
              Navigator.pop(ctx);
              _startStudying(subject: subject);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryContainer,
              foregroundColor: _onPrimaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  // ─── Check-in popup ───────────────────────────────────────────────────────

  void _showCheckinPopup() {
    if (_checkinPopupShowing || !mounted) return;
    setState(() => _checkinPopupShowing = true);
    int countdown = 60;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          countdownTimer ??=
              Timer.periodic(const Duration(seconds: 1), (_) {
            if (countdown > 0) {
              setDialogState(() => countdown--);
            }
          });
          return AlertDialog(
            backgroundColor: const Color(0xFF171A1E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Text('📚', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text(
                  'Still studying?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Confirm you\'re still here to keep your session going.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: _onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: countdown / 60,
                        strokeWidth: 6,
                        backgroundColor: _surfaceHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          countdown > 20 ? _amber : _red,
                        ),
                      ),
                    ),
                    Text(
                      '$countdown',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: countdown > 20 ? _amber : _red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Auto-stopping in ${countdown}s…',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: countdown <= 10 ? _red : _onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    _checkinGraceTimer?.cancel();
                    Navigator.pop(ctx);
                    _onCheckinConfirmed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryContainer,
                    foregroundColor: _onPrimaryContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  child: const Text('✅  Yes, I\'m still here!'),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) => countdownTimer?.cancel());

    // Grace timer fires auto-stop after 60 s of no response
    _checkinGraceTimer?.cancel();
    _checkinGraceTimer =
        Timer(const Duration(seconds: 60), () => _autoStop());
  }

  Future<void> _onCheckinConfirmed() async {
    try {
      final updated = await SessionService.confirmCheckin();
      if (mounted) {
        setState(() {
          _mySession = updated ?? _mySession;
          _checkinPopupShowing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkinPopupShowing = false);
    }
  }

  Future<void> _autoStop() async {
    if (!mounted) return;
    // ── Race condition guard: re-fetch before stopping ───────────────────────
    final updated = await SessionService.getActiveSessionForUser();
    if (updated != null && updated.checkinStatus == CheckinStatus.active) {
      // User confirmed at the last second — abort auto-stop
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        setState(() {
          _checkinPopupShowing = false;
          _mySession = updated;
        });
      }
      return;
    }
    // Proceed with auto-stop
    await SessionService.autoStopSession();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      setState(() {
        _checkinPopupShowing = false;
        _mySession = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('⏸️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Session paused — check-in missed',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7A1F1F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      await _loadSessionState();
    }
  }

  Future<void> _leaveRoom() async {
    if (_isStudying) await SessionService.stopSession();
    try {
      await RoomService.leaveRoom(widget.roomId);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
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
              _buildAppBar(),
              Expanded(
                child: Row(
                  children: [
                    _buildSidebar(),
                    Expanded(child: _buildTableArea()),
                    _buildMembersPanel(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final studierCount = _activeSessions.length;
    return Container(
      height: 64,
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
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
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(100),
              border:
                  Border.all(color: _primaryContainer.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isStudying ? _green : _onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${widget.roomName} • $studierCount Active${studierCount == 1 ? '' : ' Studiers'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _initialLoad,
            icon: const Icon(Icons.refresh_rounded,
                color: _onSurfaceVariant, size: 20),
            tooltip: 'Refresh',
          ),
          ElevatedButton.icon(
            onPressed: _leaveRoom,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Leave Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B1A1A),
              foregroundColor: const Color(0xFFFF9993),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Left Sidebar ─────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: _surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _isStudying ? 'IN SESSION' : 'ACTIVE SESSION',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: _isStudying ? _green : _onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sideItem(
            Icons.play_circle_outline_rounded,
            _isStudying ? 'Studying…' : 'Start Session',
            active: _isStudying,
            onTap: _isStudying ? null : _showStartDialog,
          ),
          _sideItem(Icons.timer_outlined, 'Timer',
              active: _isStudying, disabled: !_isStudying),
          _sideItem(Icons.how_to_reg_outlined, 'Check-in', disabled: true),
          _sideItem(Icons.info_outline_rounded, 'Session Info',
              disabled: true),
          const Spacer(),
          // My live timer bar (when studying)
          if (_isStudying && _mySession != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: _green, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    StudySessionModel.formatDuration(_mySession!.elapsed),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _green,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Room ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _outline.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag_rounded,
                    color: _onSurfaceVariant, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.roomId.substring(0, 8).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: _onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Text(
                  'ROOM ID',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    color: _outline,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(
    IconData icon,
    String label, {
    bool active = false,
    bool disabled = false,
    VoidCallback? onTap,
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
          leading:
              Icon(icon, color: active ? _green : _onSurfaceVariant, size: 20),
          title: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? _green : _onSurfaceVariant,
            ),
          ),
          onTap: disabled ? null : onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // ─── Study Table Area ──────────────────────────────────────────────────────

  Widget _buildTableArea() {
    return Stack(
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (context2, child2) => Container(
              width: 500 * _glowAnim.value,
              height: 500 * _glowAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (_isStudying ? _green : _primary)
                        .withValues(alpha: 0.06),
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
                // Shadow
                Positioned(
                  top: 20,
                  child: Container(
                    width: 460,
                    height: 460,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                // Table surface
                Container(
                  width: 460,
                  height: 460,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isStudying
                          ? [const Color(0xFF1A2520), const Color(0xFF111716)]
                          : [const Color(0xFF1C2025), const Color(0xFF111417)],
                    ),
                    border: Border.all(
                      color: (_isStudying ? _green : _outline)
                          .withValues(alpha: _isStudying ? 0.2 : 0.12),
                    ),
                  ),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: CustomPaint(
                                painter: _DotPainter(studying: _isStudying))),
                        Center(
                          child: Container(
                            width: 380,
                            height: 380,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: (_isStudying ? _green : _primary)
                                      .withValues(alpha: 0.06)),
                            ),
                            child: _isStudying
                                ? _buildStudyingCenter()
                                : _buildIdleCenter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Seat avatars
                ..._buildSeats(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleCenter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _surfaceHighest,
            border:
                Border.all(color: _outline.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.groups_2_outlined,
              color: _primary, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          _isLoading
              ? 'Loading…'
              : _memberIds.isEmpty
                  ? 'You are alone here.'
                  : 'Studying together!',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_memberIds.length} member${_memberIds.length == 1 ? '' : 's'} in this room',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: _onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _isStarting
            ? const CircularProgressIndicator(color: _primary, strokeWidth: 2)
            : ElevatedButton.icon(
                onPressed: _showStartDialog,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Studying'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryContainer,
                  foregroundColor: _onPrimaryContainer,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildStudyingCenter() {
    final elapsed = _mySession?.elapsed ?? Duration.zero;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing green ring
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) => Container(
            width: 80 * _glowAnim.value,
            height: 80 * _glowAnim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _green.withValues(alpha: 0.12 * _glowAnim.value),
              border: Border.all(
                  color: _green.withValues(alpha: 0.4 * _glowAnim.value),
                  width: 2),
            ),
            child: child,
          ),
          child: const Icon(Icons.self_improvement_rounded,
              color: _green, size: 32),
        ),
        const SizedBox(height: 16),
        // Big timer
        Text(
          StudySessionModel.formatDuration(elapsed),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: _green,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        if (_mySession?.subject != null) ...[
          Text(
            _mySession!.subject!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
        const Text(
          'IN SESSION',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: _green,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _stopStudying,
          icon: const Icon(Icons.stop_circle_outlined, size: 16),
          label: const Text('Stop Session'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _red,
            side: const BorderSide(color: _red, width: 1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSeats() {
    const positions = [
      Alignment(0, -1.1),
      Alignment(1.1, -0.5),
      Alignment(1.1, 0.5),
      Alignment(0, 1.1),
      Alignment(-1.1, 0.5),
      Alignment(-1.1, -0.5),
    ];

    return List.generate(positions.length, (i) {
      final hasUser = i < _memberIds.length;
      final userId = hasUser ? _memberIds[i] : null;
      final isMe = userId == _myUserId;
      final session = userId != null
          ? _activeSessions.where((s) => s.userId == userId).firstOrNull
          : null;
      final isActiveStudier = session != null;
      final isRecentlyMissed = !isActiveStudier &&
          userId != null &&
          _recentlyMissedUserIds.containsKey(userId);
      final status = session?.checkinStatus;

      Color seatBg;
      Color borderCol;
      Color iconCol;
      if (isRecentlyMissed) {
        seatBg = _red.withValues(alpha: 0.15);
        borderCol = _red.withValues(alpha: 0.6);
        iconCol = _red;
      } else if (isActiveStudier) {
        final isWarn = status == CheckinStatus.warning;
        seatBg = (isWarn ? _amber : _green).withValues(alpha: 0.15);
        borderCol = (isWarn ? _amber : _green).withValues(alpha: 0.6);
        iconCol = isWarn ? _amber : _green;
      } else if (hasUser) {
        seatBg = _primaryContainer.withValues(alpha: 0.3);
        borderCol = _primaryContainer;
        iconCol = isMe ? _primary : _onSurfaceVariant;
      } else {
        seatBg = Colors.transparent;
        borderCol = _outline.withValues(alpha: 0.35);
        iconCol = const Color(0xFF44484F);
      }

      return Align(
        alignment: positions[i],
        child: Tooltip(
          message: isRecentlyMissed
              ? 'Missed check-in!'
              : isMe
                  ? 'You${isActiveStudier ? ' — ${StudySessionModel.formatDuration(session.elapsed)}' : ''}'
                  : hasUser
                      ? 'Studier${isActiveStudier ? ' — ${StudySessionModel.formatDuration(session.elapsed)}' : ''}'
                      : 'Empty seat',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: seatBg,
              border: Border.all(
                color: borderCol,
                width: (isActiveStudier || isRecentlyMissed) ? 2 : 1.5,
              ),
            ),
            child: isRecentlyMissed
                ? Icon(Icons.warning_amber_rounded, color: iconCol, size: 22)
                : isActiveStudier
                    ? Icon(Icons.self_improvement_rounded,
                        color: iconCol, size: 22)
                    : hasUser
                        ? Icon(Icons.person_rounded, color: iconCol, size: 22)
                        : const Icon(Icons.add_rounded,
                            color: Color(0xFF44484F), size: 18),
          ),
        ),
      );
    });
  }

  // ─── Right Members Panel ──────────────────────────────────────────────────

  Widget _buildMembersPanel() {
    return Container(
      width: 288,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(left: BorderSide(color: Color(0x1AA7ABB3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE STUDIERS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: _onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${_activeSessions.length} Studying',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _activeSessions.isNotEmpty
                            ? _green
                            : _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_memberIds.length} in room · ${widget.roomName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x1AA7ABB3), height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary))
                : _memberIds.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _memberIds.length,
                        itemBuilder: (_, i) => _buildMemberTile(i),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(int index) {
    final userId = _memberIds[index];
    final isMe = userId == _myUserId;
    final shortId = userId.substring(0, 8).toUpperCase();

    // Live session for this member (null = not studying)
    final session =
        _activeSessions.where((s) => s.userId == userId).firstOrNull;
    final isStudying = session != null;
    final isRecentlyMissed =
        !isStudying && _recentlyMissedUserIds.containsKey(userId);
    final status = session?.checkinStatus;
    final isWarn = status == CheckinStatus.warning;

    // Derive tile accent color
    final Color accentColor = isRecentlyMissed
        ? _red
        : isStudying
            ? (isWarn ? _amber : _green)
            : _onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isRecentlyMissed || isStudying)
            ? accentColor.withValues(alpha: 0.07)
            : _surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isRecentlyMissed || isStudying)
              ? accentColor.withValues(alpha: 0.25)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: isRecentlyMissed
                      ? Icon(Icons.warning_amber_rounded,
                          color: _red, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'You' : 'Studier #${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMe ? _primary : _onSurface,
                      ),
                    ),
                    Text(
                      isRecentlyMissed ? 'Missed check-in' : shortId,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: isRecentlyMissed ? _red : _onSurfaceVariant,
                        letterSpacing: isRecentlyMissed ? 0 : 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isRecentlyMissed || isStudying)
                      ? accentColor
                      : _onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Timer + subject row (only when active)
          if (isStudying) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, color: accentColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  StudySessionModel.formatDuration(session.elapsed),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                if (session.subject != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.subject!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: _onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, color: Color(0xFF44484F), size: 40),
            SizedBox(height: 12),
            Text(
              'No members yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot grid background ──────────────────────────────────────────────────────

class _DotPainter extends CustomPainter {
  final bool studying;
  const _DotPainter({this.studying = false});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = (studying
              ? const Color(0xFF4CAF50)
              : const Color(0xFFADCBDB))
          .withValues(alpha: 0.06);
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) => old.studying != studying;
}
