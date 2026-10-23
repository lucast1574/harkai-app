import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../shared/account_avatar.dart';
import '../../core/theme.dart';

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
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final resolved = district != null && district!.isNotEmpty;
    final locality = resolved
        ? [
            district!,
            if (province != null && province != district) province!,
          ].join(', ')
        : hasPosition
        ? 'Ubicación actual'
        : 'Buscando ubicación';
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: (dark ? navy : Colors.white).withValues(
            alpha: dark ? .80 : .88,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Explorar Harkai',
                    onPressed: onExplore,
                    padding: EdgeInsets.zero,
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: OverflowBox(
                          maxWidth: 60,
                          maxHeight: 60,
                          child: Image.asset(
                            'assets/images/harkai_icon.png',
                            width: 60,
                            height: 60,
                            semanticLabel: 'Harkai',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locality,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
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
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Mi cuenta',
                    onPressed: onProfile,
                    padding: EdgeInsets.zero,
                    icon: AccountAvatar(account: account, radius: 21),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
