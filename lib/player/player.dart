import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AppStateStore with ChangeNotifier, DiagnosticableTreeMixin {
  final AudioPlayer audioPlayer = AudioPlayer();
  final ConcatenatingAudioSource playlist =
      ConcatenatingAudioSource(children: []);
  List<MediaItem> currentTracks = [];
  int currentTrackIndex = 0;

  MediaItem? get currentTrack =>
      currentTracks.isEmpty ? null : currentTracks[currentTrackIndex];

  void setCurrentTracks(List<MediaItem> tracks, {int index = 0}) {
    currentTracks = tracks;
    currentTrackIndex = index.clamp(0, tracks.isEmpty ? 0 : tracks.length - 1);
    notifyListeners();
  }

  void setCurrentTrackIndex(int index) {
    if (currentTracks.isEmpty) return;
    currentTrackIndex = index.clamp(0, currentTracks.length - 1);
    notifyListeners();
  }
}
