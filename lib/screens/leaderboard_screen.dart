import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry_model.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  // ─── Colors ───────────────────────────────────────────────────────────────
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
  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFB0BEC5);
  static const _bronze = Color(0xFFCD7F32);

  late TabController _tabController;
  final List<String> _tabs = ['Today', 'Week', 'Month', 'All Time'];

  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];
  UserStats _myStats = UserStats.zero;
  String? _statsError;
  String?
  _fetchError; // Fix #5: distinct error state for leaderboard fetch failures
  Timer? _pollTimer;

  String get _myUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) _load();
      });
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statsError = null;
      _fetchError = null; // Fix #5: clear previous error on every reload
    });
    try {
      final entries = await _fetchForTab(_tabController.index);
      var stats = UserStats.zero;
      String? statsError;

      if (_myUserId.isNotEmpty) {
        try {
          stats = await LeaderboardService.getUserStats();
        } catch (e) {
          statsError = e.toString();
        }
      }

      if (mounted) {
        setState(() {
          _entries = entries;
          _myStats = stats;
          _statsError = statsError;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fix #5: surface the real error instead of silently falling back to empty.
      if (mounted) {
        setState(() {
          _fetchError = 'Failed to load leaderboard. Tap to retry.';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<LeaderboardEntry>> _fetchForTab(int index) {
    switch (index) {
      case 0:
        return LeaderboardService.getDailyLeaderboard();
      case 1:
        return LeaderboardService.getWeeklyLeaderboard();
      case 2:
        return LeaderboardService.getMonthlyLeaderboard();
      default:
        return LeaderboardService.getAllTimeLeaderboard();
    }
  }

  int get _myRank {
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].userId == _myUserId) return i + 1;
    }
    return -1;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _fetchError != null
                ? _buildFetchError() // Fix #5: dedicated error widget
                : _entries.isEmpty
                ? _buildEmpty()
                : _buildContent(),
          ),
          _buildMyStatsBar(),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A1E), _bg],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _onSurfaceVariant,
              size: 22,
            ),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.emoji_events_rounded, color: _gold, size: 28),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Ranked by completed study hours',
                style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
              ),
            ],
          ),
          const Spacer(),
          // Refresh button
          IconButton(
            onPressed: _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _onSurfaceVariant,
              size: 20,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _outline.withValues(alpha: 0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelColor: _onPrimaryContainer,
        unselectedLabelColor: _onSurfaceVariant,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ─── Content ──────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (_entries.length >= 3) ...[
          _buildPodium(),
          const SizedBox(height: 20),
          // Rest of list (4th place onwards)
          ..._entries.skip(3).toList().asMap().entries.map((e) {
            final rank = 3 + e.key + 1;
            return _buildRankRow(e.value, rank);
          }),
        ] else ...[
          // If fewer than 3, show all as rows (no podium)
          ..._entries.asMap().entries.map(
            (e) => _buildRankRow(e.value, e.key + 1),
          ),
        ],
      ],
    );
  }

  // ─── Top 3 Podium ─────────────────────────────────────────────────────────

  Widget _buildPodium() {
    final top = _entries.take(3).toList();
    // podium order: 2nd, 1st, 3rd
    final order = [
      top.length > 1 ? top[1] : null,
      top[0],
      top.length > 2 ? top[2] : null,
    ];
    final podiumColors = [_silver, _gold, _bronze];
    final podiumLabels = ['2nd', '1st', '3rd'];
    final podiumHeights = [80.0, 110.0, 60.0];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A1E), Color(0xFF111417)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.local_fire_department_rounded, color: _gold, size: 14),
              SizedBox(width: 4),
              Text(
                'TOP CHAMPIONS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: _gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final entry = order[i];
              if (entry == null) return const SizedBox(width: 100);
              final color = podiumColors[i];
              final isMe = entry.userId == _myUserId;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Medal badge
                      _buildMedalBadge(podiumLabels[i], color),
                      const SizedBox(height: 6),
                      // Avatar circle
                      Container(
                        width: i == 1 ? 60 : 50,
                        height: i == 1 ? 60 : 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.15),
                          border: Border.all(
                            color: isMe
                                ? _primary
                                : color.withValues(alpha: 0.6),
                            width: isMe ? 2.5 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            entry.initials,
                            style: TextStyle(
                              fontSize: i == 1 ? 18 : 14,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Username
                      Text(
                        entry.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                          color: isMe ? _primary : _onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.formattedHours,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Podium bar
                      Container(
                        width: double.infinity,
                        height: podiumHeights[i],
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Rank Row ─────────────────────────────────────────────────────────────

  Widget _buildRankRow(LeaderboardEntry entry, int rank) {
    final isMe = entry.userId == _myUserId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? _primaryContainer.withValues(alpha: 0.12)
            : _surfaceHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? _primaryContainer.withValues(alpha: 0.5)
              : _outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMe ? _primary : _onSurfaceVariant,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? _primaryContainer.withValues(alpha: 0.3)
                  : _surfaceHighest,
              border: Border.all(
                color: isMe
                    ? _primary.withValues(alpha: 0.4)
                    : _outline.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isMe ? _primary : _onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    color: isMe ? _primary : _onSurface,
                  ),
                ),
                if (isMe)
                  const Text(
                    'You',
                    style: TextStyle(
                      fontSize: 10,
                      color: _primary,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          // Hours
          Text(
            entry.formattedHours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isMe ? _primary : _onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ═══ Error state (Fix #5) ═════════════════════════════════════════════

  Widget _buildFetchError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: _outline, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Could not load leaderboard.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fetchError ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryContainer,
              foregroundColor: _onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ Empty state ══════════════════════════════════════════════════════

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, color: _outline, size: 48),
          const SizedBox(height: 16),
          const Text(
            'No data yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete a study session to appear here.',
            style: TextStyle(fontSize: 13, color: _onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryContainer,
              foregroundColor: _onPrimaryContainer,
              elevation: 0,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  // ─── My stats bottom bar ──────────────────────────────────────────────────

  Widget _buildMyStatsBar() {
    final rank = _myRank;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _outline.withValues(alpha: 0.3))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: _primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                'YOUR STATS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: _onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (rank > 0)
                Text(
                  'Rank #$rank',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_statsError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _surfaceHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFFB74D),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statsError!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                _statChip('Today', _myStats.daily),
                const SizedBox(width: 8),
                _statChip('Week', _myStats.weekly),
                const SizedBox(width: 8),
                _statChip('Month', _myStats.monthly),
                const SizedBox(width: 8),
                _statChip('Total', _myStats.total),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statChip(String label, double hours) {
    final entry = LeaderboardEntry(userId: '', username: '', totalHours: hours);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              entry.formattedHours,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: _onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
