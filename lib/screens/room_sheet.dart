import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import 'room_detail_screen.dart';

final Map<String, Map<String, dynamic>> subjectMeta = {
  'Physics': {'icon': Icons.public, 'color': Colors.blue},
  'Chemistry': {'icon': Icons.science, 'color': Colors.teal},
  'Biology': {'icon': Icons.biotech, 'color': Colors.green},
  'Higher Math': {'icon': Icons.functions, 'color': Colors.deepPurple},
  'General Math': {'icon': Icons.calculate, 'color': Colors.indigo},
  'Bangla 1st': {'icon': Icons.menu_book, 'color': Colors.redAccent},
  'Bangla 2nd': {'icon': Icons.import_contacts, 'color': Colors.deepOrangeAccent},
  'English 1st': {'icon': Icons.language, 'color': Colors.purpleAccent},
  'English 2nd': {'icon': Icons.translate, 'color': Colors.pinkAccent},
  'ICT': {'icon': Icons.computer, 'color': Colors.cyan},
  'Islam': {'icon': Icons.mosque, 'color': Colors.greenAccent},
  'Hinduism': {'icon': Icons.temple_hindu, 'color': Colors.orange},
  'History': {'icon': Icons.history_edu, 'color': Colors.brown},
};

final Map<String, List<String>> categories = {
  'Science': ['Physics', 'Chemistry', 'Biology'],
  'Mathematics': ['General Math', 'Higher Math'],
  'Literacy': ['Bangla 1st', 'Bangla 2nd', 'English 1st', 'English 2nd'],
  'Religion': ['Islam', 'Hinduism'],
  'General': ['History', 'ICT'],
};

/// Bottom sheet shown when the user taps "Join Table"
class RoomSheet extends StatefulWidget {
  const RoomSheet({super.key});

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

class _RoomSheetState extends State<RoomSheet> {
  bool _isLoadingRooms = false;
  List<RoomModel> _rooms = [];

  // ─── Colors ───────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF111417);
  static const _surface = Color(0xFF171A1E);
  static const _onSurface = Color(0xFFE2E5EE);
  static const _onSurfaceVariant = Color(0xFFA7ABB3);
  static const _outline = Color(0xFF44484F);
  static const _primaryContainer = Color(0xFF395664);

  @override
  void initState() {
    super.initState();
    _loadRooms();
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

  Future<void> _joinStandardRoom(String subject) async {
    final room = _rooms.firstWhere(
      (r) => r.subject == subject && !r.isCustom,
      orElse: () => throw Exception('Standard room for $subject not found. Please refresh.'),
    );
    _joinRoom(room);
  }

  Future<void> _joinRoom(RoomModel room) async {
    // _joiningId removed
    try {
      await RoomService.joinRoom(room.id);
      if (mounted) {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          _fadeRoute(RoomDetailScreen(roomId: room.id, roomName: room.name, room: room)),
        );
      }
    } catch (e) {
      _snack('Error joining room: $e', isError: true);
    } finally {
      // _joiningId removed
    }
  }

  Future<void> _showCustomRoomDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Custom Study Room', style: TextStyle(color: _onSurface)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: _onSurface),
          decoration: InputDecoration(
            hintText: 'e.g. Personal Project, Thesis...',
            hintStyle: const TextStyle(color: _onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _outline)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryContainer),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() => _isLoadingRooms = true);
      try {
        final roomId = await RoomService.createRoom(name, subject: 'Others');
        await RoomService.joinRoom(roomId);
        if (mounted) {
          Navigator.pop(context); // close sheet
          // Create dummy room object just to pass initial data
          final dummyRoom = RoomModel(id: roomId, name: name, createdBy: '', createdAt: DateTime.now(), subject: 'Others', isCustom: true);
          Navigator.push(
            context,
            _fadeRoute(RoomDetailScreen(roomId: roomId, roomName: name, room: dummyRoom)),
          );
        }
      } catch (e) {
        _snack('Error creating room: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoadingRooms = false);
      }
    }
  }

  int _getMemberCountForSubject(String subject) {
    try {
      final rm = _rooms.firstWhere((r) => r.subject == subject && !r.isCustom);
      return rm.memberCount;
    } catch (_) {
      return 0;
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFF871F21) : const Color(0xFF395664),
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
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Study Rooms',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoadingRooms)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    IconButton(
                      onPressed: _loadRooms,
                      icon: const Icon(Icons.refresh, color: _onSurfaceVariant),
                    )
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: [
                    ...categories.entries.map((e) => _buildCategorySection(e.key, e.value)),
                    const SizedBox(height: 16),
                    _buildCustomRoomButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(String title, List<String> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _onSurfaceVariant,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: subjects.map((subj) => _buildSubjectTile(subj)).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSubjectTile(String subject) {
    final meta = subjectMeta[subject] ?? {'icon': Icons.book, 'color': Colors.grey};
    final Color color = meta['color'] as Color;
    final IconData icon = meta['icon'] as IconData;
    final count = _getMemberCountForSubject(subject);
    final isActive = count > 0;
    
    return InkWell(
      onTap: () => _joinStandardRoom(subject),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : _outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.greenAccent : _onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count active',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: isActive ? Colors.greenAccent : _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRoomButton() {
    return InkWell(
      onTap: _showCustomRoomDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryContainer.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFFC9E8F8)),
            SizedBox(width: 8),
            Text(
              'Custom Study Room',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC9E8F8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
