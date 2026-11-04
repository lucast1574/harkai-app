import 'package:flutter/material.dart';
import '../map/map_target.dart';
import '../reports/report_browser.dart';
import 'district_chat.dart';

class CommunityScreen extends StatelessWidget {
  final ValueChanged<MapTarget> onMap;
  const CommunityScreen({super.key, required this.onMap});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Chat del distrito'),
            Tab(text: 'Alertas cercanas'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              const DistrictChat(),
              ReportBrowser(
                title: 'Alertas cercanas',
                initialRadius: 2000,
                showMap: false,
                onMapTarget: onMap,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
