import 'package:flutter/material.dart';
import 'package:minimal_mp3_player/components/playlist.dart';
import 'package:minimal_mp3_player/structs/playlist.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<Playlist> playlists = [
  Playlist(title: 'Playlist 1', description: 'Description for Playlist 1'),
  Playlist(title: 'Playlist 2', description: 'Description for Playlist 2'),
  Playlist(title: 'Playlist 3', description: 'Description for Playlist 3'),
];

/// The main app.
class Library extends StatefulWidget {
  /// Constructs a [Library]
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  String? _selectedPlaylistId;
  String? _selectedPlaylistName;

  @override
  Widget build(BuildContext context) {
    if (_selectedPlaylistId != null) {
      return PlaylistScreen(
        id: _selectedPlaylistId,
        playlistName: _selectedPlaylistName,
        onBack: () => setState(() => _selectedPlaylistId = null),
      );
    }

    return LibraryMainScreen(
      onPlaylistSelected: (id, name) => setState(() {
        _selectedPlaylistId = id;
        _selectedPlaylistName = name;
      }),
    );
  }
}

class LibraryMainScreen extends StatefulWidget {
  final void Function(String id, String name) onPlaylistSelected;

  const LibraryMainScreen({super.key, required this.onPlaylistSelected});

  @override
  State<LibraryMainScreen> createState() => _LibraryMainScreenState();
}

class _LibraryMainScreenState extends State<LibraryMainScreen> {
  final TextEditingController _playlistNameController = TextEditingController();
  final _playlists = Supabase.instance.client.from('playlists').select();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Flex(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          direction: Axis.vertical,
          children: [
            const Text(
              " Your library",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder(
                  future: _playlists,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final playlists = snapshot.data!;
                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                      ),
                      itemCount: playlists.length,
                      itemBuilder: ((context, index) {
                        return GestureDetector(
                          onTap: () {
                            widget.onPlaylistSelected(
                              playlists[index]["id"].toString(),
                              playlists[index]["name"].toString(),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                ],
                              ),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    '${(index + 1).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PLAYLIST',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        playlists[index]["name"],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 19.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  }),
            ),
          ],
        ),
        Positioned(
          bottom: 15,
          right: 0,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              showShadDialog(
                context: context,
                builder: (context) => ShadDialog(
                  padding: const EdgeInsets.all(25),
                  removeBorderRadiusWhenTiny: false,
                  radius: const BorderRadius.all(Radius.circular(10)),
                  expandActionsWhenTiny: false,
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 30),
                  titleTextAlign: TextAlign.left,
                  title: const Text(
                    'Add playlist',
                  ),
                  child: Container(
                    width: 375,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShadInput(
                          controller: _playlistNameController,
                          placeholder: const Text("Playlist name"),
                        )
                      ],
                    ),
                  ),
                  actions: [
                    ShadButton(
                      child: const Text('Save changes'),
                      onPressed: () async {
                        await Supabase.instance.client
                            .from("playlists")
                            .insert({'name': _playlistNameController.text});
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
