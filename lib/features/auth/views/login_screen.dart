import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/route_maker_logo.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _consentVersion = '2026-09-10';
  static const _termsConsentKey = 'terms_consent_v1';
  static const _privacyConsentKey = 'privacy_consent_v1';
  static const _consentVersionKey = 'legal_consent_version';
  static const _consentAtKey = 'legal_consent_agreed_at';

  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _consentLoaded = false;

  bool get _allRequiredAgreed =>
      _consentLoaded && _termsAgreed && _privacyAgreed;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final preferences = await SharedPreferences.getInstance();
    final isCurrentVersion =
        preferences.getString(_consentVersionKey) == _consentVersion;
    if (!mounted) return;
    setState(() {
      _termsAgreed =
          isCurrentVersion && (preferences.getBool(_termsConsentKey) ?? false);
      _privacyAgreed =
          isCurrentVersion &&
          (preferences.getBool(_privacyConsentKey) ?? false);
      _consentLoaded = true;
    });
  }

  Future<void> _persistConsent() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_termsConsentKey, _termsAgreed);
    await preferences.setBool(_privacyConsentKey, _privacyAgreed);
    await preferences.setString(_consentVersionKey, _consentVersion);
    await preferences.setString(
      _consentAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> _signIn(Future<bool> Function() action) async {
    if (!_allRequiredAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관과 개인정보 수집·이용에 동의해주세요.')),
      );
      return;
    }
    await _persistConsent();
    if (await action() && mounted) context.go('/preferences');
  }

  void _showLegalDetails({required bool privacy}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      privacy ? '개인정보 수집·이용 동의' : '서비스 이용약관',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: SelectableText(
                  privacy ? _privacyNotice : _serviceTerms,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.65,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);
    final loading = viewModel.state == AuthState.loading;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(
            context,
          ).textTheme.apply(fontFamily: AppTheme.notoSansKr),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -80,
                        right: -100,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(28, 30, 28, 0),
                            child: RouteMakerLogo(light: true),
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              '이번 주말,\n어디로 걸어볼까요?',
                              style: TextStyle(
                                fontFamily: AppTheme.gowunDodum,
                                color: Colors.white,
                                fontSize: 32,
                                height: 1.22,
                                letterSpacing: -1.3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              '논산 · 공주 · 부여의 숨은 순간을\n당신만의 루트로 만들어드릴게요.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                            decoration: const BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  '3초 만에 여행을 시작해요',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _SocialButton(
                                  label: 'Google로 계속하기',
                                  icon: Image.asset(
                                    'assets/images/auth/google_logo.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  onTap: loading || !_allRequiredAgreed
                                      ? null
                                      : () =>
                                            _signIn(viewModel.loginWithGoogle),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: loading || !_allRequiredAgreed
                                      ? null
                                      : () =>
                                            _signIn(viewModel.continueAsGuest),
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('로그인 없이 둘러보기'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.textSecondary,
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                ),
                                if (loading)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (viewModel.errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      viewModel.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                _ConsentRow(
                                  value: _termsAgreed,
                                  label: '[필수] 서비스 이용약관 동의',
                                  onChanged: _consentLoaded
                                      ? (value) =>
                                            setState(() => _termsAgreed = value)
                                      : null,
                                  onDetails: () =>
                                      _showLegalDetails(privacy: false),
                                ),
                                _ConsentRow(
                                  value: _privacyAgreed,
                                  label: '[필수] 개인정보 수집·이용 동의',
                                  onChanged: _consentLoaded
                                      ? (value) => setState(
                                          () => _privacyAgreed = value,
                                        )
                                      : null,
                                  onDetails: () =>
                                      _showLegalDetails(privacy: true),
                                ),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(4, 5, 4, 0),
                                  child: Text(
                                    '각 상세 내용을 확인한 뒤 동의해주세요. 필수 동의 전에는 로그인 및 게스트 이용이 시작되지 않습니다.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.label,
    required this.onChanged,
    required this.onDetails,
  });

  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 36,
        height: 36,
        child: Checkbox.adaptive(
          value: value,
          onChanged: onChanged == null
              ? null
              : (checked) => onChanged!(checked ?? false),
          activeColor: AppTheme.primary,
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      TextButton(
        onPressed: onDetails,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: const Text('상세보기', style: TextStyle(fontSize: 11)),
      ),
    ],
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: onTap == null ? const Color(0xFFF0F1EE) : Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(opacity: onTap == null ? 0.45 : 1, child: icon),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: onTap == null
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

const _privacyNotice = '''시행일: 2026년 9월 10일

충남 루트메이커는 서비스 제공을 위해 아래와 같이 개인정보를 수집·이용합니다.

1. 수집 항목
• Google 로그인: Firebase 사용자 식별값(UID), 이메일 주소, 표시 이름, 프로필 사진 URL
• 게스트 이용: Firebase 익명 사용자 식별값(UID)
• 공통: 사용자가 직접 선택한 여행 지역, 동행 유형, 관심사와 코스 설정

2. 수집·이용 목적
• 사용자 인증 및 계정 구분
• 선택한 취향에 맞는 여행 코스 제공
• 찜, 여행 진행 상태 및 완주 기록 제공
• 오류 대응과 서비스 운영

3. 보유·이용 기간
계정과 서버에 저장된 정보는 회원 탈퇴 시까지 보유하며, 탈퇴 요청 시 관계 법령상 보관 의무가 있는 경우를 제외하고 삭제합니다. 앱 내부에 저장된 설정과 완주 기록은 앱 데이터 삭제 또는 탈퇴 시 삭제됩니다.

4. 위치정보 처리
현재 GPS 좌표는 주변 거리와 방문 여부를 계산하기 위해 사용자의 기기 안에서만 일시적으로 처리합니다. 현재 위치 좌표와 이동 경로는 Spring 서버 또는 외부 관광 API로 전송하거나 저장하지 않습니다. 위치 권한을 거부해도 지역별 관광정보를 볼 수 있지만, 내 주변 정렬과 GPS 도착 확인 기능은 제한됩니다.

5. 동의 거부 권리
개인정보 수집·이용에 동의하지 않을 권리가 있습니다. 다만 필수 항목 동의를 거부하면 로그인과 게스트 계정 생성 등 서비스 이용을 시작할 수 없습니다.

6. 문의
개인정보 관련 요청은 앱 마켓에 표시된 개발자 연락처를 통해 접수할 수 있습니다.''';

const _serviceTerms = '''시행일: 2026년 9월 10일

1. 목적
이 약관은 충남 루트메이커가 제공하는 관광정보, 맞춤 코스, 지도 및 여행 기록 기능의 이용 조건을 정합니다.

2. 서비스 내용
서비스는 한국관광공사 TourAPI, 기상청 API 및 지도·길찾기 정보를 조합해 여행 코스를 안내합니다. 외부 기관의 정보 갱신, 통신 상태, 현장 운영 상황에 따라 실제 영업시간·날씨·경로와 차이가 있을 수 있으므로 출발 전 해당 시설의 최신 정보를 확인해야 합니다.

3. 계정과 이용자의 책임
이용자는 Google 계정 또는 게스트 계정으로 서비스를 이용할 수 있으며, 타인의 계정을 부정하게 사용하거나 서비스 운영을 방해해서는 안 됩니다.

4. 위치 기반 기능
주변 장소 정렬과 방문 완료 기능은 이용자가 위치 권한을 허용한 경우에만 동작합니다. 앱의 코스와 길안내는 참고 정보이며 교통 법규와 현장 안전 안내를 우선해야 합니다.

5. 서비스 변경 및 중단
외부 API 장애, 점검, 천재지변 등 불가피한 사유가 있으면 서비스 일부가 일시적으로 제한될 수 있습니다. 중요한 변경 사항은 앱 또는 마켓 안내를 통해 고지합니다.

6. 동의와 철회
이용자는 로그인 전에 약관을 확인하고 명시적으로 동의해야 합니다. 동의를 철회하려면 앱의 계정 탈퇴 기능을 이용할 수 있습니다.''';
