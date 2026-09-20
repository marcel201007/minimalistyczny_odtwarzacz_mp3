import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

String removeNonLetters(String key) {
  RegExp regex = RegExp(r'[^\w\s]');
  return key.replaceAll(regex, '');
}

Future<File> _localFile(String author, String title) async {
  final path = await _localPath;
  return File('$path/$author-$title.mp3');
}

Future<void> downloadMp3FileFromYoutube(String url, int playlistId) async {
  final yt = YoutubeExplode();
  File? file;

  try {
    debugPrint('YouTube: loading video metadata...');
    final video = await yt.videos.get(url).timeout(
          const Duration(seconds: 30),
        );
    final title = video.title;
    final author = video.author;

    debugPrint('YouTube: loading audio manifest...');
    final manifest = await yt.videos.streams.getManifest(
      url,
      ytClients: [
        YoutubeApiClient.androidSdkless,
        YoutubeApiClient.androidVr,
      ],
    ).timeout(
          const Duration(seconds: 45),
        );
    final streamInfo = manifest.audioOnly.withHighestBitrate();
    final stream = yt.videos.streams.get(streamInfo);

    file = await _localFile(author, title);
    debugPrint('YouTube: downloading audio...');
    final fileStream = file.openWrite();
    final downloadCompleter = Completer<void>();
    late final StreamSubscription<List<int>> subscription;
    final timeoutTimer = Timer(const Duration(seconds: 45), () async {
      await subscription.cancel();
      if (!downloadCompleter.isCompleted) {
        downloadCompleter.completeError(
          TimeoutException('Audio download timed out'),
        );
      }
    });

    try {
      subscription = stream.listen(
        fileStream.add,
        onError: (Object error, StackTrace stackTrace) {
          if (!downloadCompleter.isCompleted) {
            downloadCompleter.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!downloadCompleter.isCompleted) {
            downloadCompleter.complete();
          }
        },
        cancelOnError: true,
      );
      await downloadCompleter.future;
      timeoutTimer.cancel();
      await fileStream.flush();
    } finally {
      timeoutTimer.cancel();
      await subscription.cancel();
      await fileStream.close();
    }

    final name = removeNonLetters(title);
    debugPrint('Supabase: uploading $name.mp3...');
    await Supabase.instance.client.storage.from('songs').upload(
          '$name.mp3',
          file,
          fileOptions:
              const FileOptions(cacheControl: '3600', upsert: true),
        );

    final publicUrl = Supabase.instance.client.storage
        .from('songs')
        .getPublicUrl('$name.mp3');

    await Supabase.instance.client.from("songs").upsert({
      "name": title,
      "author": author,
      "playlistId": playlistId,
      "nameWithoutSpecialChars": name,
      "publicUrl": publicUrl
    }, onConflict: 'name, playlistId');
    debugPrint('Supabase: upload and database record completed.');
  } finally {
    if (file != null && await file.exists()) {
      await file.delete();
    }
    yt.close();
  }
}
