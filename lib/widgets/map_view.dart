import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../config/res/config_imports.dart';
import '../core/live_activity/external_links.dart';
import '../theme/shadows.dart';

/// Map preview with the Google Maps pin at its centre and «افتح خرائط جوجل»
/// directly under it. Used both as the short strip inside the Home hero card
/// and as the taller rounded map in the order detail.
///
/// Renders a real [FlutterMap] with OpenStreetMap raster tiles (pure-Dart, no
/// native plugin — keeps the iOS build CocoaPods-free).
///
/// The map is a **still preview** by default ([interactive] off): it holds its
/// frame on the order's address instead of panning under the courier's thumb.
/// That matters twice over — a map that drags inside a scrolling card fights
/// the scroll, and it would swallow the taps of the cards these strips sit in.
/// Real navigation is Google Maps' job — and the **whole strip** is the way
/// there: tapping anywhere on the map opens the destination in Google Maps,
/// which is why the pin is Google's own mark with the label under it rather
/// than a badge tucked in a corner.
class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.height,
    this.borderRadius = 0,
    this.showHairlines = false,
    this.pinDiameter = 36,
    this.pinVerticalAlignment = 0,
    this.center,
    this.destinationLabel,
    this.showOpenInMaps = true,
    this.interactive = false,
  });

  final double height;
  final double borderRadius;

  /// Draws top+bottom hairline borders instead of clipping to a radius
  /// (the Home strip look).
  final bool showHairlines;

  /// Height of the Google pin mark at the map's centre.
  final double pinDiameter;

  /// -1 top … 0 center … 1 bottom, matching the mockups' slightly-above-center
  /// pin placement.
  final double pinVerticalAlignment;

  /// Map focus point. Defaults to central Cairo.
  final LatLng? center;

  /// Place name handed to Google Maps, so the courier lands on the destination
  /// by name rather than a bare coordinate. Falls back to lat/lng when absent.
  final String? destinationLabel;

  /// Lets the courier pan/zoom the map itself. Off everywhere in the app —
  /// see the class doc.
  final bool interactive;

  /// Shows the «افتح خرائط جوجل» label under the pin and makes the whole map
  /// open Google Maps on tap.
  final bool showOpenInMaps;

  static const LatLng _defaultCenter = LatLng(30.0444, 31.2357);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // The old breathing halo is gone with the round pin: a disc behind
  // Google's teardrop mark showed through its transparent regions, and the
  // still map costs zero frames without it.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion is a display setting, so re-evaluate whenever it
    // changes: it drives the tile fade-in.
    _reduced = AppMotion.reduced(context);
  }

  void _openMaps() {
    final LatLng focus = widget.center ?? MapView._defaultCenter;
    ExternalLinks.openInGoogleMaps(
      lat: focus.latitude,
      lng: focus.longitude,
      label: widget.destinationLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng focus = widget.center ?? MapView._defaultCenter;
    final double borderRadius = widget.borderRadius;
    final bool showHairlines = widget.showHairlines;
    final double pinDiameter = widget.pinDiameter;

    Widget map = FlutterMap(
      options: MapOptions(
        initialCenter: focus,
        initialZoom: 15,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.orderbase.orderbaseDeliveryApp',
          // Gentle fade as each tile loads so the map reads as "finding
          // location", not a broken flash. Reduce Motion → tiles appear at once.
          tileDisplay: _reduced
              ? const TileDisplay.instantaneous()
              : TileDisplay.fadeIn(duration: AppMotion.fill),
        ),
      ],
    );

    if (borderRadius > 0) {
      map = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: map,
      );
    }

    // A still map is decoration, so it must not eat the gestures of whatever it
    // is embedded in — the Home hero is tappable through this strip.
    if (!widget.interactive) map = IgnorePointer(child: map);

    // Google's own pin mark, drawn as-is: it is a multi-colour brand logo,
    // so it deliberately bypasses IconWidget, which recolours the app's
    // monochrome icon set through a srcIn filter.
    final Widget pin = SvgPicture.asset(
      'assets/brand/google_maps.svg',
      height: pinDiameter,
    );

    final Widget body = SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: showHairlines
                ? DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surfaceSubtle),
                        bottom: BorderSide(color: AppColors.surfaceSubtle),
                      ),
                    ),
                    child: map,
                  )
                : map,
          ),
          Align(
            alignment: Alignment(0, widget.pinVerticalAlignment),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                pin,
                if (widget.showOpenInMaps) ...[
                  4.szH,
                  // The hand-off label, under the pin it belongs to: the
                  // whole map is the button, this is what says so.
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppCircular.r8),
                      boxShadow: AppShadows.pin,
                    ),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppPadding.pW8,
                      vertical: AppPadding.pH4,
                    ),
                    child: Text(
                      LocaleKeys.mapOpenInGoogle.tr(),
                      style: const TextStyle().setMainTextColor.s12.semiBold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // The whole map opens Google Maps — a preview that IS the hand-off. Only
    // when the map is a still (always, in the app); a pannable map keeps its
    // gestures.
    if (widget.showOpenInMaps && !widget.interactive) {
      return Semantics(
        button: true,
        label: LocaleKeys.mapOpenInGoogle.tr(),
        child: body.onClick(onTap: _openMaps),
      );
    }
    return body;
  }
}
