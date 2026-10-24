import 'package:latlong2/latlong.dart';
import '../business/business_point.dart';
import '../../core/models.dart';
import '../help/support_place.dart';

class MapTarget {
  final String id, title;
  final LatLng point;
  final Incident? incident;
  final BusinessPoint? businessPoint;
  final SupportPlace? support;
  const MapTarget({
    required this.id,
    required this.title,
    required this.point,
    this.incident,
    this.businessPoint,
    this.support,
  });
  factory MapTarget.business(BusinessPoint p) => MapTarget(
    id: p.id,
    title: p.name,
    point: LatLng(p.latitude, p.longitude),
    businessPoint: p,
  );
  factory MapTarget.report(Incident i) => MapTarget(
    id: i.id,
    title: i.description,
    point: LatLng(i.latitude, i.longitude),
    incident: i,
  );
  factory MapTarget.place(SupportPlace p) => MapTarget(
    id: p.id,
    title: p.name,
    point: LatLng(p.latitude, p.longitude),
    support: p,
  );
}
