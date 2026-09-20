import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class PlaylistContainer extends StatelessWidget {
  final String text;
  final Function(int) onTabChanged; // Callback function

  const PlaylistContainer(
      {Key? key, required this.text, required this.onTabChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            width: 1.0, color: const Color.fromARGB(255, 44, 44, 44)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Center(
        child: ShadButton(
          child: Text("Go to $text"),
          onPressed: () {
            // Call the callback function to change the tab index
            onTabChanged(2); // Change to the index of the Library tab
          },
        ),
      ),
    );
  }
}
