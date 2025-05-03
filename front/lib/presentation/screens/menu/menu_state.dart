import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;

@immutable
class MenuState extends Equatable {
  final bool isLoading;
  final Set<String> visibleIndices; // Set으로 유지

  const MenuState({
    this.isLoading = true,
    this.visibleIndices = const {}, // 기본 빈 Set
  });

  MenuState copyWith({bool? isLoading, Set<String>? visibleIndices}) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      visibleIndices: visibleIndices ?? this.visibleIndices,
    );
  }

  @override
  List<Object?> get props => [isLoading, visibleIndices];
}
