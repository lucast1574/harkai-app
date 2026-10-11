import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models.dart';
import '../help/support_place.dart';

class CommunityMap extends StatelessWidget {
  final LatLng center;
  final LatLng? userPosition;
  final List<Incident> incidents;
  final List<SupportPlace> supportPlaces;
  final ValueChanged<Incident>? onReport;
  final ValueChanged<LatLng>? onPoint;
  const CommunityMap({
    super.key,
    required this.center,
    this.userPosition,
    this.incidents = const [],
    this.supportPlaces = const [],
    this.onReport,
    this.onPoint,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: FlutterMap(
      key: ValueKey('${center.latitude}:${center.longitude}'),
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        onTap: onPoint == null ? null : (_, point) => onPoint!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: const String.fromEnvironment(
            'HARKAI_TILE_URL',
            defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          userAgentPackageName: 'com.lucast.harkai',
        ),
        MarkerLayer(
          markers: [
            if (onPoint != null &&
                (userPosition == null ||
                    const Distance()(center, userPosition!) > 20))
              Marker(
                point: center,
                width: 42,
                height: 42,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xff267b43),
                  size: 40,
                ),
              ),
            ...supportPlaces.map(
              (p) => Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 44,
                height: 44,
                child: IconButton(
                  tooltip: p.name,
                  icon: const CircleAvatar(
                    backgroundColor: Color(0xffd94750),
                    radius: 16,
                    child: Icon(Icons.add, color: Colors.white, size: 25),
                  ),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SafeArea(
                      child: SingleChildScrollView(
                        child: SupportPlaceDetails(place: p),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...incidents.map(
              (i) => Marker(
                point: LatLng(i.latitude, i.longitude),
                width: 44,
                height: 44,
                child: IconButton(
                  tooltip: '${i.type} · ${i.verificationLabel}',
                  icon: Icon(
                    Icons.location_on,
                    size: 34,
                    color: i.verified
                        ? const Color(0xff267b43)
                        : const Color(0xffc28c2e),
                  ),
                  onPressed: onReport == null ? null : () => onReport!(i),
                ),
              ),
            ),
            if (userPosition != null)
              Marker(
                point: userPosition!,
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff267eff),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
