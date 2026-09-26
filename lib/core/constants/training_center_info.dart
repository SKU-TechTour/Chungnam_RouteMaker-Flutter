/// 우편 주소는 길찾기 좌표가 아니라 육군훈련소 홈페이지의 우편 안내입니다.
abstract final class TrainingCenterInfo {
  static const name = '육군훈련소';
  static const postalAddress = '[33011] 충남 논산시 연무읍 사서함 76-1호~16호';
  static const officialGuideUrl = 'https://www.katc.mil.kr/katc/guide/map.jsp';

  static bool isTrainingCenter(String id, String name) =>
      id == '-1' || name == TrainingCenterInfo.name;
}
