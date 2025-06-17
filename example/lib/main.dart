import 'package:example/tabs/asset_link.dart';
import 'package:example/tabs/yt_live.dart';
import 'package:example/tabs/network_link.dart';
import 'package:example/tabs/yt.dart';
import 'package:example/tabs/vimeo.dart';
import 'package:example/tabs/yt_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omni_video_player/omni_video_player.dart';

void main() {
  runApp(
    MaterialApp(
      home: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Omni Video Players'),
            bottom: const TabBar(
              padding: EdgeInsets.zero,
              tabAlignment: TabAlignment.center,
              isScrollable: true,
              tabs: [
                Tab(text: 'YT'),
                Tab(text: 'YT Live'),
                Tab(text: 'Network Link'),
                Tab(text: 'Asset Link'),
                Tab(text: 'Vimeo'),
                Tab(text: 'YT Error'),
              ],
            ),
          ),
          body: BlocProvider(
            create: (_) => GlobalPlaybackController(),
            child: const TabBarView(
              children: [
                YT(),
                YTLive(),
                NetworkLink(),
                AssetLink(),
                Vimeo(),
                YTError(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
