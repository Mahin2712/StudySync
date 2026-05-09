import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_ui_state.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard/top_app_bar.dart';
import '../widgets/dashboard/left_sidebar.dart';
import '../widgets/dashboard/main_canvas.dart';
import '../widgets/dashboard/right_panel/right_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  final bool _isSidebarExpanded = true;
  bool _isRightSidebarExpanded = true;

  // Chat
  final _chatService = ChatService();

  // Dashboard Data
  DashboardData? _dashboardData;
  bool _isLoadingDashboard = true;
  String? _dashboardError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatService.joinGlobalChat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowController.dispose();
    _chatService.leaveGlobalChat();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final data = await DashboardService.getDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardError = 'Failed to load dashboard data.';
          _isLoadingDashboard = false;
        });
      }
    }
  }

  DashboardUiState get _uiState => DashboardUiState(
        data: _dashboardData,
        isLoading: _isLoadingDashboard,
        error: _dashboardError,
      );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Scaffold(
      endDrawer: isNarrow ? Drawer(
        width: 320,
        backgroundColor: const Color(0xFF111417),
        child: DashboardRightPanel(
          isMobile: true,
          isExpanded: true,
          uiState: _uiState,
          chatService: _chatService,
          onRefresh: _loadDashboardData,
          onExpand: () {}, // Not used in drawer
        ),
      ) : null,
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Radial background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF171A1E), AppColors.bg],
                ),
              ),
            ),
          ),

          Column(
            children: [
              DashboardTopAppBar(
                isNarrow: isNarrow,
                isRightSidebarExpanded: _isRightSidebarExpanded,
                uiState: _uiState,
                onToggleRightSidebar: () {
                  if (isNarrow) {
                    Scaffold.of(context).openEndDrawer();
                  } else {
                    setState(() => _isRightSidebarExpanded = !_isRightSidebarExpanded);
                  }
                },
              ),
              Expanded(
                child: Row(
                  children: [
                    // Left sidebar
                    if (!isNarrow || _isSidebarExpanded)
                      DashboardLeftSidebar(isNarrow: isNarrow),

                    // Main canvas
                    Expanded(
                      child: DashboardMainCanvas(
                        glowAnim: _glowAnim,
                        uiState: _uiState,
                      ),
                    ),

                    // Right panel
                    if (!isNarrow)
                      DashboardRightPanel(
                        isMobile: false,
                        isExpanded: _isRightSidebarExpanded,
                        uiState: _uiState,
                        chatService: _chatService,
                        onRefresh: _loadDashboardData,
                        onExpand: () => setState(() => _isRightSidebarExpanded = true),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
