import 'package:example/tabs/asset_link.dart';
import 'package:example/tabs/file_video.dart';
import 'package:example/tabs/network_link.dart';
import 'package:example/tabs/vimeo.dart';
import 'package:example/tabs/yt.dart';
import 'package:example/tabs/yt_live.dart';
import 'package:example/tabs/yt_web.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: DefaultTabController(
        length: 7,
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
                Tab(text: 'YT Web'),
                Tab(text: 'Network Link'),
                Tab(text: 'Asset Link'),
                Tab(text: 'File video'),
                Tab(text: 'Vimeo'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              YT(),
              YTLive(),
              YTWeb(),
              NetworkLink(),
              AssetLink(),
              FileVideo(),
              Vimeo(),
            ],
          ),
        ),
      ),
    ),
  );
}
