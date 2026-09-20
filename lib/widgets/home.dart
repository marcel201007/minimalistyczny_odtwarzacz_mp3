import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:minimal_mp3_player/player/common.dart';
import 'package:minimal_mp3_player/player/player.dart';
import 'package:minimal_mp3_player/widgets/download.dart';
import 'package:minimal_mp3_player/widgets/library.dart';
import 'package:minimal_mp3_player/widgets/now_playing.dart';
import 'package:minimal_mp3_player/widgets/settings.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
  bool _showTrackPicker = false;
  FixedExtentScrollController? _trackPickerController;
  Timer? _pickerCommitTimer;

  late final player =
      Provider.of<AppStateStore>(context, listen: false).audioPlayer;

  Stream<PositionData> _positionDataStream() =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    _redirect();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.black),
    );
  }

  @override
  void dispose() {
    _pickerCommitTimer?.cancel();
    _trackPickerController?.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    if (Supabase.instance.client.auth.currentSession == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _toggleTrackPicker(int currentIndex) {
    setState(() {
      _showTrackPicker = !_showTrackPicker;
      if (_showTrackPicker) {
        _trackPickerController?.dispose();
        _trackPickerController = FixedExtentScrollController(
          initialItem: currentIndex,
        );
        _pickerCommitTimer?.cancel();
        _pickerCommitTimer = Timer(
          const Duration(seconds: 1),
          _closeTrackPicker,
        );
      } else {
        _pickerCommitTimer?.cancel();
        _trackPickerController?.dispose();
        _trackPickerController = null;
      }
    });
  }

  void _closeTrackPicker() {
    if (!mounted || !_showTrackPicker) return;
    _pickerCommitTimer?.cancel();
    setState(() {
      _showTrackPicker = false;
      _trackPickerController?.dispose();
      _trackPickerController = null;
    });
  }

  void _openNowPlaying() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.96,
        child: NowPlayingPage(),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final appState = context.watch<AppStateStore>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: _showTrackPicker ? 209 : 137,
      decoration: BoxDecoration(
        border: _showTrackPicker
            ? null
            : const Border(
                top: BorderSide(color: Color(0xff252525)),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final metadata = appState.currentTrack;
              if (metadata == null || appState.currentTracks.isEmpty) {
                return const SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      'No current track',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }

              final safePickerIndex = appState.currentTrackIndex;
              return AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  height: _showTrackPicker ? 104 : 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_showTrackPicker)
                        Align(
                          alignment: Alignment.topCenter,
                          child: CupertinoPicker(
                              itemExtent: 32,
                              squeeze: 1.15,
                              useMagnifier: true,
                              magnification: 1.08,
                              scrollController: _trackPickerController,
                              onSelectedItemChanged: (index) {
                                _pickerCommitTimer?.cancel();
                                _pickerCommitTimer = Timer(
                                  const Duration(seconds: 1),
                                  () async {
                                    if (!mounted) return;
                                    await player.seek(
                                      Duration.zero,
                                      index: index,
                                    );
                                    context
                                        .read<AppStateStore>()
                                        .setCurrentTrackIndex(index);
                                    await player.setVolume(1.0);
                                    unawaited(player.play());
                                    _closeTrackPicker();
                                  },
                                );
                              },
                              children: [
                                for (final track in appState.currentTracks)
                                  Center(
                                    child: Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                              ],
                          ),
                        )
                      else
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openNowPlaying,
                          onLongPress: () =>
                              _toggleTrackPicker(safePickerIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 42,
                              vertical: 7,
                            ),
                            child: Text(
                              metadata.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    if (!_showTrackPicker)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Open player',
                          icon: const Icon(Icons.open_in_full),
                          iconSize: 22,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: _openNowPlaying,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                visualDensity: VisualDensity.compact,
                onPressed: player.hasPrevious ? player.seekToPrevious : null,
              ),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final isLoading = state?.processingState ==
                          ProcessingState.loading ||
                      state?.processingState == ProcessingState.buffering;
                  if (isLoading) {
                    return const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final isPlaying = state?.playing ?? false;
                  return IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: isPlaying ? player.pause : player.play,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                visualDensity: VisualDensity.compact,
                onPressed: player.hasNext ? player.seekToNext : null,
              ),
            ],
          ),
            StreamBuilder<PositionData>(
            stream: _positionDataStream(),
            builder: (context, snapshot) {
              final position = snapshot.data;
              return SeekBar(
                duration: position?.duration ?? Duration.zero,
                position: position?.position ?? Duration.zero,
                bufferedPosition: position?.bufferedPosition ?? Duration.zero,
                onChangeEnd: player.seek,
              );
            },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (index) {
          setState(() => currentPageIndex = index);
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.library_music),
            icon: Icon(Icons.library_music_outlined),
            label: 'Library',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.download),
            icon: Icon(Icons.download_outlined),
            label: 'Download',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: [
                const Library(),
                const Download(),
                const Settings(),
              ][currentPageIndex],
            ),
          ),
          _buildMiniPlayer(),
        ],
      ),
    );
  }
}
