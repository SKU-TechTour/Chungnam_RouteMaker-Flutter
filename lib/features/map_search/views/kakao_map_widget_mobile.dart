import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutterprojects/features/map_search/viewmodels/map_search_state.dart';

Widget buildKakaoMap({
  required MapSearchState state,
  required void Function(Object controller) onCreated,
}) {
  return KakaoMap(
    onMapCreated: (c) => onCreated(c),
    center: LatLng(36.4465, 127.1191),
    currentLevel: 8,
    markers: state.places
        .map((p) => Marker(markerId: p.id, latLng: LatLng(p.lat, p.lng)))
        .toList(),
  );
}

void moveKakaoMap(Object? controller, double lat, double lng) {
  (controller as KakaoMapController?)?.setCenter(LatLng(lat, lng));
}
