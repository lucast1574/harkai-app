import 'package:flutter/material.dart';
import 'support_place.dart';
import 'support_proximity.dart';

class NearbySupportCard extends StatelessWidget {
  final List<NearbySupport> nearby;
  const NearbySupportCard({super.key, required this.nearby});
  @override
  Widget build(BuildContext context) {
    if (nearby.isEmpty) return const SizedBox.shrink();
    final first = nearby.first;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xffd94750),
          child: Icon(Icons.add, color: Colors.white),
        ),
        title: const Text('Tienes un lugar de salud cerca'),
        subtitle: Text(
          '${first.place.name} · aprox. ${first.meters.round()} m\n'
          '${nearby.length} ${nearby.length == 1 ? 'lugar a menos' : 'lugares a menos'} de 500 m. '
          'Son puntos permanentes, no alertas.',
        ),
        isThreeLine: true,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => SafeArea(
            child: SingleChildScrollView(
              child: SupportPlaceDetails(place: first.place),
            ),
          ),
        ),
      ),
    );
  }
}
