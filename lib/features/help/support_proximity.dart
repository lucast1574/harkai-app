import 'package:latlong2/latlong.dart';
import 'support_place.dart';

class NearbySupport {
  final SupportPlace place;
  final double meters;
  const NearbySupport(this.place, this.meters);
}

List<NearbySupport> nearbySupport(
  List<SupportPlace> places,
  LatLng position, {
  double accuracy = 0,
  double radius = 500,
}) {
  if (!accuracy.isFinite || accuracy < 0 || accuracy > 150) return [];
  const distance = Distance();
  final nearby = places
      .map(
        (p) => NearbySupport(
          p,
          distance(position, LatLng(p.latitude, p.longitude)),
        ),
      )
      .where((p) => p.meters <= radius)
      .toList();
  nearby.sort((a, b) => a.meters.compareTo(b.meters));
  return nearby;
}
