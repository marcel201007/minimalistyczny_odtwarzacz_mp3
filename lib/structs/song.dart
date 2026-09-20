import 'dart:ffi';

class Song {
  final Int songId;
  final String name;
  final Int16 playlistId;

  Song({required this.songId, required this.name, required this.playlistId});
}
