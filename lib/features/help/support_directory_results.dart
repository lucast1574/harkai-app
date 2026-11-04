import 'package:latlong2/latlong.dart';
import 'support_place.dart';
import 'support_proximity.dart';

List<NearbySupport> supportDirectoryResults(
  List<SupportPlace> places,
  LatLng point, {
  double radius = 2000,
  String kind = '',
  String search = '',
}) {
  final query = search.trim().toLowerCase();
  const distance = Distance();
  final items = places
      .where(
        (p) =>
            p.latitude.isFinite &&
            p.longitude.isFinite &&
            p.latitude.abs() <= 90 &&
            p.longitude.abs() <= 180,
      )
      .map(
        (p) =>
            NearbySupport(p, distance(point, LatLng(p.latitude, p.longitude))),
      )
      .where(
        (item) =>
            item.meters <= radius &&
            (kind.isEmpty ||
                (kind == 'health'
                    ? ['health_center', 'hospital'].contains(item.place.kind)
                    : item.place.kind == kind)) &&
            '${item.place.name} ${item.place.district} ${item.place.address}'
                .toLowerCase()
                .contains(query),
      )
      .toList();
  items.sort((a, b) => a.meters.compareTo(b.meters));
  return items;
}
