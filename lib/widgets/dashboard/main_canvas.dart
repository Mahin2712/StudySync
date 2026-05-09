import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/room_sheet.dart';
import 'recent_rooms.dart';
import '../../models/dashboard_ui_state.dart';

class DashboardMainCanvas extends StatelessWidget {
  final Animation<double> glowAnim;
  final DashboardUiState uiState;

  const DashboardMainCanvas({
    super.key,
    required this.glowAnim,
    required this.uiState,
  });

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
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.outlineVariant,
            size: 18,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Atmospheric glow
              Center(
                child: AnimatedBuilder(
                  animation: glowAnim,
                  builder: (_, _) => Container(
                    width: 500 * glowAnim.value,
                    height: 500 * glowAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.04),
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
                                color: Colors.black.withValues(alpha: 0.5),
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
                            color: AppColors.outlineVariant.withValues(alpha: 0.12),
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
                                      color: AppColors.primary.withValues(alpha: 0.05),
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
                                          color: AppColors.surfaceHighest,
                                          border: Border.all(
                                            color: AppColors.outlineVariant.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.chair_alt_rounded,
                                          color: AppColors.primary,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'The room is quiet.',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurface,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 48),
                                        child: Text(
                                          'Ready to start your focused study session? Be the first to take a seat.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.onSurfaceVariant,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      ElevatedButton(
                                        onPressed: () => RoomSheet.show(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryContainer,
                                          foregroundColor: AppColors.onPrimaryContainer,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                          shape: const StadiumBorder(),
                                          textStyle: const TextStyle(
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
          ),
        ),
        DashboardRecentRooms(uiState: uiState),
      ],
    );
  }
}

// ─── Dot Grid Painter ──────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
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
