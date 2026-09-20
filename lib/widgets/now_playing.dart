import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:minimal_mp3_player/player/common.dart';
import 'package:minimal_mp3_player/player/player.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  Stream<PositionData> _positionDataStream(AudioPlayer player) =>
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
  Widget build(BuildContext context) {
    final player = context.read<AppStateStore>().audioPlayer;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Close player',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                  const Expanded(
                    child: Text(
                      'NOW PLAYING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final coverSize = math.min(
                      300.0,
                      math.max(180.0, constraints.maxHeight * 0.42),
                    );

                    return StreamBuilder<SequenceState?>(
                      stream: player.sequenceStateStream,
                      builder: (context, snapshot) {
                    final state = snapshot.data;
                    final tag = state?.currentSource?.tag;
                    final metadata = tag is MediaItem ? tag : null;
                    final title = metadata?.title ?? 'No current track';
                    final playlist = metadata?.album ?? 'Playlist';

                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          SizedBox(
                            width: coverSize,
                            height: coverSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xff364152),
                                  Color(0xff111827),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 24,
                                  offset: Offset(0, 14),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 92,
                              color: Colors.white70,
                            ),
                          ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            playlist,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                          ),
                          const SizedBox(height: 14),
                          StreamBuilder<PositionData>(
                          stream: _positionDataStream(player),
                          builder: (context, positionSnapshot) {
                            final position = positionSnapshot.data;
                            return SeekBar(
                              duration: position?.duration ?? Duration.zero,
                              position: position?.position ?? Duration.zero,
                              bufferedPosition:
                                  position?.bufferedPosition ?? Duration.zero,
                              onChangeEnd: player.seek,
                            );
                          },
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 30,
                                  onPressed: player.hasPrevious
                                      ? player.seekToPrevious
                                      : null,
                                  icon: const Icon(Icons.skip_previous),
                                ),
                                const SizedBox(width: 18),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(18),
                                  ),
                                  onPressed:
                                      playing ? player.pause : player.play,
                                  child: Icon(
                                    playing ? Icons.pause : Icons.play_arrow,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                IconButton(
                                  iconSize: 30,
                                  onPressed:
                                      player.hasNext ? player.seekToNext : null,
                                  icon: const Icon(Icons.skip_next),
                                ),
                              ],
                            );
                          },
                          ),
                          ],
                        ),
                      ),
                    );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
