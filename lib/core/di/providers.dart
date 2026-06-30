import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/network/dio_client.dart';
import 'package:flutterprojects/core/utils/location_util.dart';
import 'package:flutterprojects/features/home_curation/repositories/course_repository.dart';
import 'package:flutterprojects/features/home_curation/viewmodels/home_curation_viewmodel.dart';
import 'package:flutterprojects/features/map_search/repositories/place_repository.dart';
import 'package:flutterprojects/features/map_search/viewmodels/map_search_viewmodel.dart';
import 'package:flutterprojects/features/military_guide/data/platform/live_widget_channel.dart';
import 'package:flutterprojects/features/military_guide/repositories/military_repository.dart';
import 'package:flutterprojects/features/military_guide/viewmodels/military_guide_viewmodel.dart';
import 'package:flutterprojects/features/my_history/repositories/reward_remote_repository.dart';
import 'package:flutterprojects/features/my_history/repositories/stamp_local_repository.dart';
import 'package:flutterprojects/features/my_history/viewmodels/my_history_viewmodel.dart';

/// 앱 전역 의존성 주입 (Riverpod Provider).
///
/// Repository → ViewModel 의존 체인을 여기서 연결합니다.
/// View는 ref.watch(viewModelProvider)만 사용합니다.

final dioProvider = Provider((ref) => DioClient.instance.dio);

final locationUtilProvider = Provider((ref) => const LocationUtil());

final liveWidgetChannelProvider = Provider((ref) => LiveWidgetChannel());

// --- Repositories ---

final courseRepositoryProvider = Provider(
  (ref) => CourseRepository(ref.watch(dioProvider)),
);

final militaryRepositoryProvider = Provider(
  (ref) => MilitaryRepository(
    dio: ref.watch(dioProvider),
    liveWidgetChannel: ref.watch(liveWidgetChannelProvider),
  ),
);

final placeRepositoryProvider = Provider(
  (ref) => PlaceRepository(ref.watch(dioProvider)),
);

final rewardRemoteRepositoryProvider = Provider(
  (ref) => RewardRemoteRepository(ref.watch(dioProvider)),
);

final stampLocalRepositoryProvider = Provider(
  (ref) => StampLocalRepository(),
);

// --- ViewModels ---

final homeCurationViewModelProvider =
    NotifierProvider<HomeCurationViewModel, HomeCurationState>(
  HomeCurationViewModel.new,
);

final militaryGuideViewModelProvider =
    NotifierProvider<MilitaryGuideViewModel, MilitaryGuideState>(
  MilitaryGuideViewModel.new,
);

final mapSearchViewModelProvider =
    NotifierProvider<MapSearchViewModel, MapSearchState>(
  MapSearchViewModel.new,
);

final myHistoryViewModelProvider =
    NotifierProvider<MyHistoryViewModel, MyHistoryState>(
  MyHistoryViewModel.new,
);
