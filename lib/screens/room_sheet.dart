import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import 'room_detail_screen.dart';

/// Bottom sheet shown when the user taps "Join Table"
class RoomSheet extends StatefulWidget {
  const RoomSheet({super.key});

  /// Helper — call this from any widget to show the sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RoomSheet(),
    );
  }

  @override
  State<RoomSheet> createState() => _RoomSheetState();
}

class _RoomSheetState extends State<RoomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _roomNameCtrl = TextEditingController();
  bool _isCreating = false;
  bool _isLoadingRooms = false;
  List<RoomModel> _rooms = [];
  String? _joiningId;

  // ─── Colors ───────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF111417);
  static const _surface = Color(0xFF171A1E);
  static const _surfaceHigh = Color(0xFF22262C);
  static const _primary = Color(0xFFADCBDB);
  static const _primaryContainer = Color(0xFF395664);
  static const _onPrimaryContainer = Color(0xFFC9E8F8);
  static const _onSurface = Color(0xFFE2E5EE);
  static const _onSurfaceVariant = Color(0xFFA7ABB3);
  static const _outline = Color(0xFF44484F);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadRooms();
  }

  @override
  void dispose() {
    _tab.dispose();
    _roomNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final rooms = await RoomService.fetchRooms();
      if (mounted) setState(() => _rooms = rooms);
    } catch (e) {
      _snack('Failed to load rooms: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  Future<void> _createRoom() async {
    final name = _roomNameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Please enter a room name.', isError: true);
      return;
    }
    setState(() => _isCreating = true);
    try {
      final roomId = await RoomService.createRoom(name);
      await RoomService.joinRoom(roomId);
      if (mounted) {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          _fadeRoute(RoomDetailScreen(roomId: roomId, roomName: name)),
        );
      }
    } catch (e) {
      _snack('Error creating room: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinRoom(RoomModel room) async {
    setState(() => _joiningId = room.id);
    try {
      await RoomService.joinRoom(room.id);
      if (mounted) {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          _fadeRoute(RoomDetailScreen(roomId: room.id, roomName: room.name)),
        );
      }
    } catch (e) {
      _snack('Error joining room: $e', isError: true);
    } finally {
      if (mounted) setState(() => _joiningId = null);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? const Color(0xFF871F21) : _primaryContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Color(0x1144484F), width: 1),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.meeting_room_outlined,
                          color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study Rooms',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _onSurface,
                          ),
                        ),
                        Text(
                          'Create or join a focused study room',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: _onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  labelColor: _onPrimaryContainer,
                  unselectedLabelColor: _onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  indicator: BoxDecoration(
                    color: _primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '✦ Create Room'),
                    Tab(text: '⊞ Join Room'),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildCreateTab(scrollCtrl),
                    _buildJoinTab(scrollCtrl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Create Tab ───────────────────────────────────────────────────────────
  Widget _buildCreateTab(ScrollController scrollCtrl) {
    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _outline.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryContainer.withValues(alpha: 0.2),
                    border: Border.all(
                        color: _primaryContainer.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: _primary, size: 32),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Start a new room',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Give your room a name and invite\nyour study group to join.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: _onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'ROOM NAME',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              letterSpacing: 1.4,
              color: _onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _roomNameCtrl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Quantum Physics • Chapter 4',
              hintStyle: const TextStyle(
                  color: Color(0xFF72767D), fontSize: 13),
              filled: true,
              fillColor: _surface,
              prefixIcon: const Icon(Icons.meeting_room_outlined,
                  color: _onSurfaceVariant, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: _outline.withValues(alpha: 0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: _outline.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _createRoom(),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createRoom,
              icon: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _onPrimaryContainer))
                  : const Icon(Icons.rocket_launch_outlined, size: 18),
              label: Text(_isCreating ? 'Creating...' : 'Create Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryContainer,
                foregroundColor: _onPrimaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Join Tab ─────────────────────────────────────────────────────────────
  Widget _buildJoinTab(ScrollController scrollCtrl) {
    return Column(
      children: [
        // Refresh button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Row(
            children: [
              const Text(
                'AVAILABLE ROOMS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: 1.4,
                  color: _onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _isLoadingRooms ? null : _loadRooms,
                icon: const Icon(Icons.refresh_rounded,
                    size: 16, color: _primary),
                label: const Text('Refresh',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12, color: _primary)),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingRooms
              ? const Center(
                  child: CircularProgressIndicator(color: _primary))
              : _rooms.isEmpty
                  ? _buildEmptyRooms()
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      itemCount: _rooms.length,
                      itemBuilder: (_, i) => _buildRoomCard(_rooms[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyRooms() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _surface,
              border: Border.all(
                  color: _outline.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: _onSurfaceVariant, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'No rooms yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first to create a study room!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _tab.animateTo(0),
            child: const Text(
              '← Switch to Create Room',
              style: TextStyle(
                  fontFamily: 'Inter', color: _primary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final isJoining = _joiningId == room.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: _outline.withValues(alpha: 0.35), width: 1),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.table_restaurant_rounded,
              color: _primary, size: 22),
        ),
        title: Text(
          room.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 13, color: _onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${room.memberCount} ${room.memberCount == 1 ? 'member' : 'members'}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: _onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: room.memberCount > 0
                    ? const Color(0xFF4CAF50)
                    : _outline,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              room.memberCount > 0 ? 'Active' : 'Empty',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: room.memberCount > 0
                    ? const Color(0xFF4CAF50)
                    : _outline,
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 88,
          height: 36,
          child: ElevatedButton(
            onPressed: isJoining ? null : () => _joinRoom(room),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryContainer,
              foregroundColor: _onPrimaryContainer,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: isJoining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _onPrimaryContainer))
                : const Text('Join'),
          ),
        ),
      ),
    );
  }
}
