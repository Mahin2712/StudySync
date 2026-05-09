import '../services/dashboard_service.dart';

class DashboardUiState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  const DashboardUiState({
    this.data,
    this.isLoading = true,
    this.error,
  });

  DashboardUiState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return DashboardUiState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
