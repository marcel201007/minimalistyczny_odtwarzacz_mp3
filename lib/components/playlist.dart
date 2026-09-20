import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:minimal_mp3_player/player/player.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistScreen extends StatefulWidget {
  // Corrected constructor declaration
  final String? id;
  final String? playlistName;
  final VoidCallback? onBack;

  const PlaylistScreen({
    Key? key,
    required this.id,
    this.playlistName,
    this.onBack,
  })
      : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late String? id;
  late PostgrestFilterBuilder _songs; // Declare _songs here
  late PostgrestFilterBuilder _playlistName;
  late Future<String> _playlistTitle;
  late final player =
      Provider.of<AppStateStore>(context, listen: false).audioPlayer;

  Future<void> _startPlayback() async {
    try {
      await player.play();
    } catch (error) {
      _showPlaybackError(error);
    }
  }

  String _audioUrl(Map<String, dynamic> song) {
    final storedUrl = song['publicUrl']?.toString();
    if (storedUrl != null && storedUrl.isNotEmpty) {
      final oldUri = Uri.tryParse(storedUrl);
      final currentUri = Uri.parse(
        Supabase.instance.client.storage
            .from('songs')
            .getPublicUrl('placeholder.mp3'),
      );
      if (oldUri != null) {
        final normalizedPath =
            oldUri.path.replaceFirst('/songs/public/', '/songs/');
        return oldUri.replace(
          scheme: currentUri.scheme,
          host: currentUri.host,
          port: currentUri.hasPort ? currentUri.port : null,
          path: normalizedPath,
        ).toString();
      }
    }

    final fileName = song['nameWithoutSpecialChars']?.toString();
    return Supabase.instance.client.storage
        .from('songs')
      .getPublicUrl('$fileName.mp3');
  }

  void _showPlaybackError(Object error) {
    debugPrint('Playback failed: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nie można odtworzyć tego utworu.'),
      ),
    );
  }

  Future<void> _playFromIndex(List<dynamic> songs, int index) async {
    try {
      final songsToPlay = songs;
      final audioUrls = songsToPlay
          .map<String>((song) => _audioUrl(song as Map<String, dynamic>))
          .toList();
      debugPrint('Audio URLs: $audioUrls');

      final audioSources = songsToPlay
          .map(
            (song) => AudioSource.uri(
              Uri.parse(_audioUrl(song as Map<String, dynamic>)),
              tag: MediaItem(
                id: song['id'].toString(),
                title: song['name'].toString(),
                album: widget.playlistName,
              ),
            ),
          )
          .toList();
      final mediaItems = audioSources
            .map((source) => source.tag as MediaItem)
            .toList();

      final audioPlaylist = ConcatenatingAudioSource(children: audioSources);
      debugPrint('Setting audio source...');
      await player.setShuffleModeEnabled(false);
      await player.setAudioSource(
        audioPlaylist,
        initialIndex: index,
      );
      context.read<AppStateStore>().setCurrentTracks(
        mediaItems,
        index: index,
      );
      debugPrint('Audio source ready, starting playback...');
      await player.setVolume(1.0);
      unawaited(_startPlayback());
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint(
        'Playback state: playing=${player.playing}, '
        'processingState=${player.processingState}, '
        'position=${player.position}',
      );
    } catch (error) {
      _showPlaybackError(error);
    }
  }

  @override
  void initState() {
    super.initState();
    id = widget.id;
    if (id != null) {
      _songs = Supabase.instance.client
          .from('songs')
          .select()
          .eq("playlistId", int.parse(widget.id ?? ""));
    }
    _playlistName = Supabase.instance.client
        .from("playlists")
        .select()
        .eq('id', int.parse(widget.id ?? ""));
    _playlistTitle = _playlistName.then(
      (rows) => rows.isEmpty ? 'Playlist' : rows.first['name'].toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flex(
          direction: Axis.horizontal,
          children: [
            IconButton(
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                )),
            const SizedBox(
              width: 10,
            ),
            FutureBuilder(
                future: _playlistName,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var playlist = snapshot.data;
                    return Text(
                      playlist[0]['name'],
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    );
                  } else {
                    return const Text(
                      "Loading...",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    );
                  }
                })
          ],
        ),
        FutureBuilder(
            future: _songs, // Call query() on _songs
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Expanded(
                    child: Center(child: CircularProgressIndicator()));
              }
              final songs = snapshot.data!;
              if (songs.length > 0) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  shrinkWrap: true,
                  itemCount: songs.length,
                  itemBuilder: ((BuildContext context, int index) {
                    final song = songs[index];
                    return ListTile(
                      onTap: () => _playFromIndex(songs, index),
                      dense: true,
                      title: Text(
                        "${(index + 1).toString()} . ${song["name"]} - ${song["author"]}",
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }),
                );
              } else {
                return const Expanded(
                  child: Center(
                      child: Text(
                    "No songs on this playlist",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                );
              }
            }),
      ],
    );
  }
}
