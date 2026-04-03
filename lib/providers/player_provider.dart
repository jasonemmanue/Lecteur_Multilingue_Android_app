// lib/providers/player_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerState {
  final bool isOriginalAudio;
  final bool showSubtitles;
  final bool isLoading;
  final String? error;

  const PlayerState({
    this.isOriginalAudio = false, // traduit par défaut
    this.showSubtitles   = true,
    this.isLoading       = true,
    this.error,
  });

  PlayerState copyWith({
    bool? isOriginalAudio,
    bool? showSubtitles,
    bool? isLoading,
    String? error,
  }) {
    return PlayerState(
      isOriginalAudio: isOriginalAudio ?? this.isOriginalAudio,
      showSubtitles:   showSubtitles   ?? this.showSubtitles,
      isLoading:       isLoading       ?? this.isLoading,
      error:           error           ?? this.error,
    );
  }
}

final playerProvider =
StateNotifierProvider.autoDispose<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerState());

  void setLoaded()  => state = state.copyWith(isLoading: false);
  void setError(String msg) =>
      state = state.copyWith(isLoading: false, error: msg);

  void toggleAudio() =>
      state = state.copyWith(isOriginalAudio: !state.isOriginalAudio);

  void toggleSubtitles() =>
      state = state.copyWith(showSubtitles: !state.showSubtitles);

  void reset() => state = const PlayerState();
}