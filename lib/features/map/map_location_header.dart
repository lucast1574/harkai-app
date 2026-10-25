import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../shared/account_avatar.dart';
import 'map_glass_surface.dart';

class MapLocationHeader extends StatelessWidget {
  final Account? account;
  final String? district, province;
  final bool hasPosition;
  final VoidCallback? onExplore, onProfile;
  const MapLocationHeader({
    super.key,
    this.account,
    this.district,
    this.province,
    required this.hasPosition,
    this.onExplore,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xffedf4f7)
        : const Color(0xff163044);
    final resolved = district != null && district!.isNotEmpty;
    final locality = resolved
        ? [
            district!,
            if (province != null && province != district) province!,
          ].join(', ')
        : hasPosition
        ? 'Ubicación actual'
        : 'Buscando ubicación';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MapGlassSurface(
          neutral: true,
          radius: 18,
          child: SizedBox(
            width: 50,
            height: 50,
            child: IconButton(
              tooltip: 'Explorar Harkai',
              onPressed: onExplore,
              padding: const EdgeInsets.all(10),
              icon: Image.asset(
                'assets/images/logo.png',
                width: 30,
                height: 34,
                semanticLabel: 'Harkai',
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MapGlassSurface(
            neutral: true,
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locality,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (resolved) ...[
                        // Peru's civil flag is drawn directly, never rendered as an emoji.
                        Semantics(
                          label: 'Bandera de Perú',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              width: 18,
                              height: 12,
                              child: Row(
                                children: const [
                                  Expanded(
                                    child: ColoredBox(
                                      color: Color(0xffd62b3b),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                  Expanded(
                                    child: ColoredBox(
                                      color: Colors.white,
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                  Expanded(
                                    child: ColoredBox(
                                      color: Color(0xffd62b3b),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        resolved
                            ? 'Perú'
                            : hasPosition
                            ? 'Identificando distrito…'
                            : 'Activa el GPS',
                        style: TextStyle(
                          color: foreground.withValues(alpha: .72),
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        MapGlassSurface(
          neutral: true,
          radius: 18,
          child: SizedBox(
            width: 50,
            height: 50,
            child: IconButton(
              tooltip: 'Mi cuenta',
              onPressed: onProfile,
              padding: const EdgeInsets.all(7),
              icon: AccountAvatar(account: account, radius: 18),
            ),
          ),
        ),
      ],
    );
  }
}
