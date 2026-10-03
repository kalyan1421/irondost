import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../design/theme.dart';

/// Hyderabad city centre: where the map opens when we don't know where the customer is.
const _hyderabad = LatLng(17.385, 78.4867);

/// Lets the screen move the map when a search result or the phone's location is chosen.
class PinMapController {
  GoogleMapController? _map;

  Future<void> moveTo(double latitude, double longitude) async {
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 17));
  }
}

/// Google Map with the pin fixed at its centre: the customer moves the map, not the pin.
/// [onMoved] fires when the camera comes to rest.
class PinMap extends StatefulWidget {
  const PinMap({super.key, required this.controller, required this.onMoved, this.initialLatitude, this.initialLongitude});

  final PinMapController controller;
  final void Function(double latitude, double longitude) onMoved;
  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<PinMap> createState() => _PinMapState();
}

class _PinMapState extends State<PinMap> {
  LatLng? _center;
  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final start = widget.initialLatitude == null ? _hyderabad : LatLng(widget.initialLatitude!, widget.initialLongitude!);
    return Stack(
      alignment: Alignment.center,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: start, zoom: widget.initialLatitude == null ? 12 : 17),
          onMapCreated: (m) => widget.controller._map = m,
          onCameraMove: (p) => _center = p.target,
          onCameraIdle: () {
            final center = _center;
            if (center == null) return;
            // Ignore the first idle after a programmatic move to the same spot.
            _settle?.cancel();
            _settle = Timer(const Duration(milliseconds: 250), () => widget.onMoved(center.latitude, center.longitude));
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
        // The pin's tip sits on the exact centre of the map.
        IgnorePointer(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: ExcludeSemantics(
              child: Icon(Icons.location_on, size: 48, color: c.royal, shadows: [Shadow(color: c.ink.withValues(alpha: 0.4), blurRadius: 6)]),
            ),
          ),
        ),
      ],
    );
  }
}
