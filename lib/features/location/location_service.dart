import 'package:geolocator/geolocator.dart';

Future<Position> currentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception(
      'Activa la ubicación del dispositivo o elige el punto manualmente.',
    );
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception(
      'Sin permiso de ubicación. Puedes elegir el punto manualmente.',
    );
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    ),
  );
}
