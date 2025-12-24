import 'package:example/tabs/asset_link.dart';
import 'package:example/tabs/file_video.dart';
import 'package:example/tabs/m3u8_network_link.dart';
import 'package:example/tabs/network_link.dart';
import 'package:example/tabs/vimeo.dart';
import 'package:example/tabs/webm_network_link.dart';
import 'package:example/tabs/yt.dart';
import 'package:example/tabs/yt_live.dart';
import 'package:example/tabs/yt_web.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: DefaultTabController(
        length: 9,
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
                Tab(text: 'YT WebView'),
                Tab(text: 'Vimeo'),
                Tab(text: 'Network Link'),
                Tab(text: 'm3u8 Network Link'),
                Tab(text: 'WEBM Network Link'),
                Tab(text: 'Asset Link'),
                Tab(text: 'File video'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              YT(),
              YTLive(),
              YTWeb(),
              Vimeo(),
              NetworkLink(),
              M3u8NetworkLink(),
              WebmNetworkLink(),
              AssetLink(),
              FileVideo(),
            ],
          ),
        ),
      ),
    ),
  );
}
