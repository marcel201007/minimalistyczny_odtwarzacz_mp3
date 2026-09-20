import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minimal_mp3_player/utils/download_mp3.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Download extends StatefulWidget {
  const Download({super.key});

  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download> {
  final TextEditingController _urlTextController = TextEditingController();
  final _playlists = Supabase.instance.client.from('playlists').select();

  int playlistId = 0;
  bool _isDownloading = false;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _urlTextController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlTextController.removeListener(_onUrlChanged);
    _urlTextController.dispose();
    super.dispose();
  }

  // Detects a YouTube video id in the pasted link so we can show a preview.
  void _onUrlChanged() {
    final id = _extractVideoId(_urlTextController.text.trim());
    if (id != _videoId) {
      setState(() => _videoId = id);
    }
  }

  static String? _extractVideoId(String url) {
    final match = RegExp(
      r'(?:youtu\.be/|youtube\.com/(?:watch\?(?:.*&)?v=|embed/|shorts/|live/))([A-Za-z0-9_-]{11})',
    ).firstMatch(url);
    return match?.group(1);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _urlTextController.text = text;
    }
  }

  Future<void> _startDownload() async {
    FocusScope.of(context).unfocus();
    final url = _urlTextController.text.trim();

    if (playlistId == 0 || url.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Choose a playlist and paste a YouTube link first'),
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    var downloadSucceeded = false;
    try {
      await downloadMp3FileFromYoutube(url, playlistId);
      downloadSucceeded = true;
    } catch (error) {
      debugPrint('Download failed: $error');
    }

    if (!mounted) return;
    setState(() => _isDownloading = false);
    if (downloadSucceeded) _urlTextController.clear();

    final toaster = ShadToaster.of(context);
    if (downloadSucceeded) {
      toaster.show(
        const ShadToast(
          duration: Duration(seconds: 2),
          title: Text('Added to your playlist'),
        ),
      );
    } else {
      toaster.show(
        const ShadToast.destructive(
          duration: Duration(seconds: 3),
          title: Text('Download failed'),
          description: Text('Check the link and your connection, then retry.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(theme: theme),
          const SizedBox(height: 24),
          ShadCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel(
                  theme: theme,
                  icon: Icons.queue_music_rounded,
                  text: 'Playlist',
                ),
                const SizedBox(height: 8),
                _buildPlaylistSelect(theme),
                const SizedBox(height: 20),
                _FieldLabel(
                  theme: theme,
                  icon: LucideIcons.link,
                  text: 'YouTube link',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ShadInput(
                        controller: _urlTextController,
                        enabled: !_isDownloading,
                        keyboardType: TextInputType.url,
                        placeholder: const Text('https://youtu.be/...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShadIconButton.outline(
                      icon: const Icon(LucideIcons.clipboardPaste, size: 16),
                      onPressed: _isDownloading ? null : _pasteFromClipboard,
                    ),
                  ],
                ),
                _buildPreview(theme),
                const SizedBox(height: 20),
                ShadButton(
                  width: double.infinity,
                  enabled: !_isDownloading,
                  onPressed: _startDownload,
                  leading: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.download, size: 16),
                  child: Text(_isDownloading ? 'Downloading…' : 'Download MP3'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: theme.colorScheme.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The track is converted to MP3 and saved in the playlist you chose.',
                    style: theme.textTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistSelect(ShadThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _playlists,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Could not load playlists.',
            style: theme.textTheme.small
                .copyWith(color: theme.colorScheme.destructive),
          );
        }
        if (!snapshot.hasData) {
          // Quiet placeholder instead of a spinner in the middle of the screen.
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        final playlists = snapshot.data!;
        if (playlists.isEmpty) {
          return Text(
            'No playlists yet. Create one first.',
            style: theme.textTheme.muted,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) => ShadSelect<String>(
            enabled: !_isDownloading,
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
            placeholder: const Text('Select a playlist'),
            options: [
              for (final playlist in playlists)
                ShadOption(
                  value: playlist['id'].toString(),
                  child: Row(
                    children: [
                      Icon(Icons.library_music_outlined,
                          size: 16,
                          color: theme.colorScheme.mutedForeground),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          playlist['name'].toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            selectedOptionBuilder: (context, value) {
              final name = playlists.firstWhere(
                  (element) => element['id'].toString() == value)['name'];
              return Row(
                children: [
                  Icon(Icons.library_music_outlined,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(name.toString(),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              );
            },
            onChanged: (value) {
              if (value != null) {
                playlistId = int.parse(value);
                debugPrint(playlistId.toString());
              }
            },
          ),
        );
      },
    );
  }

  // The one "memorable" element: a video preview that appears once a valid
  // link is pasted, so the person can confirm they have the right track.
  Widget _buildPreview(ShadThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _videoId == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://img.youtube.com/vi/$_videoId/mqdefault.jpg',
                        key: ValueKey(_videoId),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.muted,
                          alignment: Alignment.center,
                          child: Icon(Icons.music_note_rounded,
                              size: 40,
                              color: theme.colorScheme.mutedForeground),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.45),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Link recognised',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            LucideIcons.download,
            color: theme.colorScheme.primaryForeground,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Download',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text('Turn a YouTube video into a track',
                  style: theme.textTheme.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.theme,
    required this.icon,
    required this.text,
  });

  final ShadThemeData theme;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 8),
        Text(text, style: theme.textTheme.small),
      ],
    );
  }
}