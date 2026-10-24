import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../help/support_place.dart';
import 'user_location_marker.dart';
import '../business/business_point.dart';

class CommunityMap extends StatefulWidget {
  final LatLng center;
  final List<BusinessPoint> businesses;
  final ValueChanged<BusinessPoint>? onBusiness;
  final LatLng? target;
  final String? selectedId;
  final ValueChanged<SupportPlace>? onSupport;
  final LatLng? userPosition;
  final List<Incident> incidents;
  final List<SupportPlace> supportPlaces;
  final ValueChanged<Incident>? onReport;
  final ValueChanged<LatLng>? onPoint;
  final VoidCallback? onBackgroundTap;
  final ValueChanged<LatLng>? onLongPressPoint;
  final bool fullScreen;
  final double initialZoom;
  final int focusRequest;
  final bool userPositionFresh;
  final double bottomObstruction, topObstruction;
  const CommunityMap({
    super.key,
    required this.center,
    this.businesses = const [],
    this.onBusiness,
    this.target,
    this.selectedId,
    this.onSupport,
    this.userPosition,
    this.incidents = const [],
    this.supportPlaces = const [],
    this.onReport,
    this.onPoint,
    this.onBackgroundTap,
    this.onLongPressPoint,
    this.fullScreen = false,
    this.initialZoom = 13.5,
    this.focusRequest = 0,
    this.userPositionFresh = true,
    this.bottomObstruction = 0,
    this.topObstruction = 0,
  });

  @override
  State<CommunityMap> createState() => _CommunityMapState();
}

class _CommunityMapState extends State<CommunityMap> {
  final MapController _controller = MapController();
  bool _ready = false;

  void focusTarget() {
    if (widget.target == null) return;
    if (widget.userPosition == null) {
      _controller.move(widget.target!, 16.5);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: [widget.userPosition!, widget.target!],
        padding: EdgeInsets.fromLTRB(48, widget.topObstruction + 48, 48, 300),
        maxZoom: 17,
      ),
    );
  }

  void focusOnUser() {
    _controller.move(
      widget.userPosition ?? widget.center,
      16.5,
      offset: Offset(0, (widget.topObstruction - widget.bottomObstruction) / 2),
    );
  }

  @override
  void didUpdateWidget(covariant CommunityMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        widget.target != null &&
        (oldWidget.target != widget.target ||
            oldWidget.userPosition == null && widget.userPosition != null)) {
      focusTarget();
      return;
    }
    if (_ready && oldWidget.focusRequest != widget.focusRequest) {
      focusOnUser();
      return;
    }
    if (widget.target != null) return;
    if (_ready &&
        (oldWidget.center.latitude != widget.center.latitude ||
            oldWidget.center.longitude != widget.center.longitude)) {
      final zoom = _controller.camera.zoom;
      _controller.move(
        widget.center,
        zoom < 11 ? widget.initialZoom : zoom,
        offset: Offset(
          0,
          (widget.topObstruction - widget.bottomObstruction) / 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.initialZoom,
        onMapReady: () {
          _ready = true;
          if (widget.target != null) {
            focusTarget();
          } else if (widget.focusRequest > 0) {
            focusOnUser();
          }
        },
        onTap: (_, point) {
          if (widget.onPoint != null) {
            widget.onPoint!(point);
          } else {
            widget.onBackgroundTap?.call();
          }
        },
        onLongPress: widget.onLongPressPoint == null
            ? null
            : (_, point) => widget.onLongPressPoint!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: const String.fromEnvironment(
            'HARKAI_TILE_URL',
            defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          userAgentPackageName: 'com.lucast.harkai',
        ),
        if (widget.incidents.isNotEmpty)
          CircleLayer(
            circles: widget.incidents.map((i) {
              final visual = categoryVisual(i.type);
              return CircleMarker(
                point: LatLng(i.latitude, i.longitude),
                radius: 85,
                useRadiusInMeter: true,
                color: visual.color.withValues(alpha: 0.16),
                borderColor: visual.color.withValues(alpha: 0.55),
                borderStrokeWidth: 1.5,
              );
            }).toList(),
          ),
        if (widget.target != null && widget.userPosition != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [widget.userPosition!, widget.target!],
                color: green,
                strokeWidth: 4,
              ),
            ],
          ),
        if (widget.target != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.target!,
                width: 70,
                height: 70,
                child: const Icon(Icons.location_on, size: 64, color: green),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (widget.onPoint != null)
              Marker(
                point: widget.center,
                width: 44,
                height: 44,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: green.withValues(alpha: 0.25),
                      border: Border.all(color: navy, width: 2.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        color: navy,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ...widget.businesses.map(
              (p) => Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 72,
                height: 72,
                child: GestureDetector(
                  onTap: () => widget.onBusiness?.call(p),
                  child: Tooltip(
                    message: "${p.name} · Promocionado",
                    child: Container(
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: green, width: 3),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: green,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...widget.supportPlaces.map(
              (p) => Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 22,
                height: 22,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSupport != null
                      ? () => widget.onSupport!(p)
                      : () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => SafeArea(
                            child: SingleChildScrollView(
                              child: SupportPlaceDetails(place: p),
                            ),
                          ),
                        ),
                  child: Tooltip(
                    message: p.name,
                    child: Center(
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xffd94750),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...widget.incidents.map((i) {
              final visual = categoryVisual(i.type);
              return Marker(
                point: LatLng(i.latitude, i.longitude),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: widget.onReport == null
                      ? null
                      : () => widget.onReport!(i),
                  child: Tooltip(
                    message: '${visual.shortLabel} · ${i.verificationLabel}',
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: visual.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 7,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CategoryGlyph(
                              type: i.type,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (i.verified)
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: green,
                                shape: BoxShape.circle,
                                border: Border.all(color: navy, width: 1.4),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 9,
                                color: navy,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (widget.userPosition != null)
              Marker(
                point: widget.userPosition!,
                width: 108,
                height: 108,
                child: UserLocationMarker(fresh: widget.userPositionFresh),
              ),
          ],
        ),
        Positioned(
          left: 8,
          bottom: widget.fullScreen ? 116 : 6,
          child: GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.fullScreen) return map;
    return ClipRRect(borderRadius: BorderRadius.circular(20), child: map);
  }
}
