import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry_model.dart';
import '../services/leaderboard_service.dart';
import '../services/subject_service.dart';

/// Self-insight stats dashboard for the current user.
/// Shows time overview cards (Today / Week / Month / Total) and
/// a subject-breakdown list. Non-standard subjects are bucketed as "Others".
class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  // ─── Design tokens (matches RoomDetailScreen palette) ─────────────────────
  static const _bg = Color(0xFF0C0E11);
  static const _surface = Color(0xFF111417);
  static const _surfaceHigh = Color(0xFF1C2025);
  static const _surfaceHighest = Color(0xFF22262C);
  static const _primary = Color(0xFFADCBDB);
  static const _primaryCont = Color(0xFF395664);
  static const _onPrimaryCont = Color(0xFFC9E8F8);
  static const _onSurface = Color(0xFFE2E5EE);
  static const _onSurfaceVar = Color(0xFFA7ABB3);
  static const _outline = Color(0xFF44484F);
  static const _green = Color(0xFF4CAF50);
  static const _amber = Color(0xFFFFB74D);
  static const _red = Color(0xFFFF6B6B);

  // ─── State ────────────────────────────────────────────────────────────────
  UserStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('Not logged in');
      await SubjectService.getSubjects(); // Prefetch dynamic subjects cache
      final stats = await LeaderboardService.getUserStats(uid);
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = null;
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Format a double-hours value into "Xh Ym" or "Xm".
  String _fmt(double hours) {
    if (hours <= 0) return '0m';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _error != null
                ? _buildError()
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _onSurfaceVar,
                size: 18,
              ),
            ),
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
          const Text(
            'My Stats',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _onSurfaceVar,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _onSurfaceVar,
              size: 20,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: _onSurfaceVar,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryCont,
                foregroundColor: _onPrimaryCont,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final stats = _stats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ─────────────────────────────────────────────────
          _sectionLabel('OVERVIEW'),
          const SizedBox(height: 12),

          // ── Overview cards row ────────────────────────────────────────────
          _buildOverviewCards(stats),

          const SizedBox(height: 28),

          // ── Verified note ─────────────────────────────────────────────────
          _buildVerifiedNote(),

          const SizedBox(height: 28),

          // ── Subject breakdown ─────────────────────────────────────────────
          if (stats.subjectBreakdown.isNotEmpty) ...[
            _sectionLabel('SUBJECT BREAKDOWN'),
            const SizedBox(height: 12),
            _buildSubjectList(stats),
          ] else ...[
            _buildNoSubjectState(),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        letterSpacing: 1.8,
        color: _onSurfaceVar,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildOverviewCards(UserStats stats) {
    final cards = [
      _CardData(
        'Today',
        _fmt(stats.daily),
        Icons.wb_sunny_outlined,
        _amber,
        'Confirmed study time today',
      ),
      _CardData(
        'Weekly',
        _fmt(stats.weekly),
        Icons.date_range_outlined,
        _primary,
        'Last 7 days',
      ),
      _CardData(
        'Monthly',
        _fmt(stats.monthly),
        Icons.calendar_month_outlined,
        _green,
        'This month',
      ),
      _CardData(
        'All Time',
        _fmt(stats.total),
        Icons.emoji_events_outlined,
        const Color(0xFFCF9D5E),
        'Total verified',
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: cards.map((c) => _buildCard(c)).toList(),
    );
  }

  Widget _buildCard(_CardData c) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: c.color.withValues(alpha: 0.04),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(c.icon, color: c.color, size: 16),
              ),
              const Spacer(),
              Tooltip(
                message: c.tooltip,
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: _outline,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: _onSurfaceVar,
            ),
          ),
        ],
      ),
    );
  }

  // Small disclaimer banner
  Widget _buildVerifiedNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _outline.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: const [
          Icon(Icons.verified_outlined, color: _primary, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stats count only confirmed intervals. '
              'Sessions auto-stopped on missed check-ins are not counted.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _onSurfaceVar,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(UserStats stats) {
    // Sort: known subjects first (alphabetical), then 'others' last.
    final entries = stats.subjectBreakdown.entries.toList()
      ..sort((a, b) {
        if (a.key == 'others') return 1;
        if (b.key == 'others') return -1;
        return a.key.compareTo(b.key);
      });

    final totalHours = stats.subjectBreakdown.values.fold(
      0.0,
      (sum, h) => sum + h,
    );

    final subjects = SubjectService.getCachedSubjects();
    final subjectMap = {for (var s in subjects) s.key: s};

    return Column(
      children: entries.map((e) {
        final isOthers = e.key == 'others';
        final subjectInfo = subjectMap[e.key];

        final displayName = isOthers
            ? 'Others'
            : (subjectInfo?.displayName ?? _titleCase(e.key));
        final emoji = isOthers ? '📝' : (subjectInfo?.emoji ?? '📚');

        final fraction = totalHours > 0 ? (e.value / totalHours) : 0.0;
        final barColor = isOthers ? _outline : _primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _outline.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _onSurface,
                          ),
                        ),
                        if (isOthers)
                          const Text(
                            'Custom / unrecognised subjects',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: _onSurfaceVar,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _fmt(e.value),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOthers ? _onSurfaceVar : _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: _surfaceHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    barColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoSubjectState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: const [
          Icon(Icons.menu_book_outlined, color: _outline, size: 40),
          SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _onSurface,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Complete your first study session to see\nyour subject breakdown here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: _onSurfaceVar,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }
}

// ─── Internal helper ──────────────────────────────────────────────────────────

class _CardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String tooltip;

  const _CardData(this.label, this.value, this.icon, this.color, this.tooltip);
}
