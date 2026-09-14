import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Only cache tiles requested for the visible map. The existing image cache
/// honours HTTP expiry headers; web uses the browser's HTTP cache.
class CachedMapTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return kIsWeb
        ? NetworkImage(url)
        : CachedNetworkImageProvider(url, headers: headers);
  }
}
