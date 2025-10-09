import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class FileVideo extends StatefulWidget {
  const FileVideo({super.key});

  @override
  State<FileVideo> createState() => _FileVideoState();
}

class _FileVideoState extends State<FileVideo> {
  File? _videoFile;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _videoFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ElevatedButton(
              onPressed: _pickVideo,
              child: const Text('Select a video from your phone'),
            ),
          ),

          Expanded(
            child:
                _videoFile != null
                    ? Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: OmniVideoPlayer(
                        // Using a unique ValueKey based on the file path ensures the OmniVideoPlayer
                        // is rebuilt from scratch whenever a new video file is selected.
                        key: ValueKey(_videoFile!.path),
                        callbacks: VideoPlayerCallbacks(
                          onControllerCreated: (controller) {
                            // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
                          },
                        ),
                        options: VideoPlayerConfiguration(
                          videoSourceConfiguration:
                              VideoSourceConfiguration.file(
                                videoFile: _videoFile!,
                              ),
                          playerUIVisibilityOptions: PlayerUIVisibilityOptions(
                            useSafeAreaForBottomControls: true,
                            showPlaybackSpeedButton: true,
                          ),
                          customPlayerWidgets: CustomPlayerWidgets().copyWith(
                            loadingWidget: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          playerTheme: OmniVideoPlayerThemeData().copyWith(
                            shapes: VideoPlayerShapeTheme().copyWith(
                              borderRadius: 0,
                            ),
                            colors: VideoPlayerColorScheme().copyWith(
                              active: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    )
                    : Center(
                      child: const Text(
                        'No video selected',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
