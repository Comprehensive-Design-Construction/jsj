// lib/presentation/screens/index_detail/index_detail_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class IndexDetailState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String recommendation;

  const IndexDetailState({
    this.isLoading = true,
    this.errorMessage,
    this.recommendation = '행동 요령을 불러오는 중...',
  });

  IndexDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? recommendation,
  }) {
    return IndexDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      recommendation: recommendation ?? this.recommendation,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, recommendation];
}
