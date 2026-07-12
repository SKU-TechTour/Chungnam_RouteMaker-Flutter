import 'package:kakao_map_plugin/kakao_map_plugin.dart';

Future<void> initKakaoMap() async {
  KakaoMapSdk.instance.initialize(appKey: '2eb004abce6828a6761254c044751c36');
}
