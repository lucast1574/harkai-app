import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../shared/account_avatar.dart';
import 'map_glass_surface.dart';

class MapLocationHeader extends StatelessWidget {
  final Account? account;
  final String? district, province;
  final bool hasPosition, embedded;
  final VoidCallback? onExplore, onProfile;
  const MapLocationHeader({
    super.key,
    this.account,
    this.district,
    this.province,
    required this.hasPosition,
    this.embedded = false,
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
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: 'Explorar Harkai',
              onPressed: onExplore,
              padding: const EdgeInsets.all(10),
              icon: Image.asset(
                'assets/images/logo.png',
                width: 30,
                height: 32,
                semanticLabel: 'Harkai',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locality,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (resolved) ...[
                      Semantics(
                        label: 'Bandera de Perú',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: 14,
                            height: 9,
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
                    Flexible(
                      child: Text(
                        resolved
                            ? 'Perú'
                            : hasPosition
                            ? 'Identificando distrito…'
                            : 'Activa el GPS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground.withValues(alpha: .74),
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: 'Mi cuenta',
              onPressed: onProfile,
              padding: const EdgeInsets.all(5),
              icon: AccountAvatar(account: account, radius: 18),
            ),
          ),
        ],
      ),
    );
    return embedded
        ? content
        : MapGlassSurface(neutral: true, radius: 28, child: content);
  }
}
