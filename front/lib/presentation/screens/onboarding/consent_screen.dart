// lib/presentation/screens/onboarding/consent_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/presentation/screens/onboarding/onboarding_info_input_screen.dart'; // 정보 입력 화면 경로
import '../../../core/utils/preferences_service.dart'; // PreferencesService import
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider 사용

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  // 각 동의 항목 상태 (null: 선택 안됨, true: 동의, false: 비동의)
  bool? agree1;
  bool? agree2;
  bool? agree3;
  bool? agree4;

  // 모든 필수 항목이 선택되었는지 확인하는 getter
  bool get allConsentsSelected =>
      agree1 != null && agree2 != null && agree3 != null && agree4 != null;
  // 모든 필수 항목에 동의했는지 확인하는 getter
  bool get allAgreed =>
      agree1 == true && agree2 == true && agree3 == true && agree4 == true;

  @override
  Widget build(BuildContext context) {
    final prefsService = ref.read(
      preferencesServiceProvider,
    ); // PreferencesService 인스턴스 가져오기

    return Scaffold(
      backgroundColor: Colors.white, // 배경색 유지 또는 테마 적용
      appBar: AppBar(
        // AppBar 스타일은 AppTheme에서 자동으로 적용될 수 있음
        title: const Text('개인정보 제공 및 활용 동의'), // 제목 약간 수정
        leading: IconButton(
          // 뒤로가기 버튼 추가 (WelcomeScreen으로 돌아감)
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        elevation: 0.5, // 약간의 그림자 추가
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 동의 내용 (스타일 적용) ---
            sectionTitle('1. 개인정보 수집 항목'),
            bulletPoint('이용자의 이름, 성별, 생년월일'),
            bulletPoint('이용자의 기저질환'),
            bulletPoint('이용자의 위치 정보(구, 동)'),
            bulletPoint(
              '개인정보 보유 및 이용기간 : 5년 혹은 동의 철회 시까지',
              isBold: true,
            ), // 문구 수정
            const SizedBox(height: 8),
            infoText(
              '※ 개인정보의 수집이용과 관련하여 동의를 거부할 권리가 있으며, 동의 거부 시 서비스 이용에 제한이 있을 수 있습니다.',
            ),
            infoText('※ 동의 철회 시 해당 정보는 지체 없이 파기됩니다.'),
            infoText('※ 어플 내 활동 외 사용자의 정보를 추가적인 데이터베이스에 저장하거나 사용하지 않습니다.'),
            // consentCardWithMinorNotice(agree1, (val) { // '만 14세' 관련 고지는 필수 동의 항목과 분리하는 것이 일반적
            //   setState(() { agree1 = val; });
            // }),
            consentCard('개인정보 수집 및 이용 동의', agree1, (val) {
              // 제목 추가
              setState(() {
                agree1 = val;
              });
            }),

            sectionTitle('2. 수집정보의 활용범위'),
            bulletPoint('사용자 건강 지수 계산에 사용자의 나이 및 사용자 위치 정보(구, 동) 활용'),
            bulletPoint('대피소 위치 및 환경 지도 제공에 사용자의 위치 정보(구, 동) 활용'),
            bulletPoint('맞춤형 행동 요령 제공에 사용자의 성별 및 기저질환, 특이사항 정보 활용'),
            bulletPoint('(정보 제공 대상 : 서비스 제공 업체)'),
            consentCard('개인정보 활용 범위 동의', agree2, (val) {
              // 제목 추가
              setState(() {
                agree2 = val;
              });
            }),

            sectionTitle('3. 민감정보 수집 및 이용 동의'), // 제목 약간 수정
            infoText('※ 기저질환 유무와 같은 민감정보의 수집 및 이용에 대해 별도로 동의합니다.'),
            consentCard('민감정보 수집 및 이용 동의', agree3, (val) {
              // 제목 추가
              setState(() {
                agree3 = val;
              });
            }),
            sectionTitle('4. 가족 및 지인 건강관리 기능 활용 동의'),
            bulletPoint(
              '본인은 앱 내 가족 및 지인 건강관리 기능 사용 시 구성원의 건강정보(예: 이름, 나이, 관계, 기저질환 등)를 입력하고 저장하는 데 동의하며, ',
            ),
            bulletPoint('해당 정보는 구성원 간의 건강 모니터링 및 맞춤형 건강관리 서비스를 위해 활용됩니다.'),
            bulletPoint(
              '만 14세 미만 아동의 정보 입력 시, 본인은 법정대리인으로서 동의 권한이 있음을 확인합니다.\n',
            ),
            consentCard("건강관리 기능 활용 동의", agree4, (val) {
              setState(() {
                agree4 = val;
              });
            }),

            const SizedBox(height: 24),
            // --- 버튼 영역 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 취소 버튼 (먼저 배치)
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // WelcomeScreen으로 돌아감
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ), // 버튼 크기 조정
                    side: BorderSide(color: Colors.grey.shade400), // 테두리 색상
                    foregroundColor: Colors.grey.shade700, // 글자색
                  ),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 16),
                // 확인(제출) 버튼
                ElevatedButton(
                  onPressed: () async {
                    // async 추가
                    if (!allConsentsSelected) {
                      // 모든 항목 선택 여부 확인
                      _showAlertDialog('동의 필요', '모든 항목에 대해 동의 또는 비동의를 선택해주세요.');
                    } else if (allAgreed) {
                      // 모든 항목 동의 여부 확인
                      try {
                        // 동의 상태 저장
                        await prefsService.setConsentGiven(true);
                        // 정보 입력 화면으로 이동 (현재 화면을 스택에서 제거하고 새 화면 표시)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingInfoInputScreen(),
                          ),
                        );
                      } catch (e) {
                        print("Error saving consent: $e");
                        _showAlertDialog('오류', '동의 상태 저장 중 오류가 발생했습니다.');
                      }
                    } else {
                      // 하나라도 비동의 시
                      // 동의 거부 상태 저장 (선택적)
                      // await prefsService.setConsentGiven(false);
                      // 동의 거부 알림 후 WelcomeScreen으로 돌아감
                      _showAlertDialog(
                        '동의 거부됨',
                        '개인정보 활용에 동의하지 않으시면 서비스 이용이 제한될 수 있습니다.',
                        // onConfirm:
                        //     () => Navigator.of(context).pop(), // 현재 Alert 닫기
                        onClosed: () {
                          // Alert 닫힌 후 WelcomeScreen으로 이동
                          if (mounted) {
                            // 추가적인 mounted 체크
                            Navigator.of(context).pop(); // ConsentScreen 닫기
                          }
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).primaryColor, // 테마 기본 색상 사용
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ), // 버튼 크기 조정
                  ),
                  child: const Text('확인'), // 버튼 텍스트 변경
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper 위젯들 (스타일 적용) ---
  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium, // 테마 스타일 적용
      ),
    );
  }

  Widget bulletPoint(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            ' • ',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ), // 글머리 기호 변경
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                // 테마 스타일 적용
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87, // 일반 텍스트 색상
                height: 1.5, // 줄간격 조정
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 12,
        ), // 테마 기본 색상 적용
      ),
    );
  }

  // 동의/비동의 선택 카드 (UI 개선)
  Widget consentCard(
    String title,
    bool? agreeValue,
    Function(bool?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ), // 타이틀 추가
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 정렬
            children: [
              _buildConsentOption(true, agreeValue, onChanged),
              const SizedBox(width: 16),
              _buildConsentOption(false, agreeValue, onChanged),
            ],
          ),
          Divider(height: 24, color: Colors.grey.shade300), // 구분선 추가
        ],
      ),
    );
  }

  // 동의/비동의 선택 옵션 위젯
  Widget _buildConsentOption(
    bool isAgree,
    bool? groupValue,
    Function(bool?) onChanged,
  ) {
    return InkWell(
      // 탭 영역 확장
      onTap: () => onChanged(isAgree),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<bool?>(
            // Checkbox 대신 Radio 사용 (하나만 선택)
            value: isAgree,
            groupValue: groupValue,
            onChanged: (val) => onChanged(val),
            activeColor: Theme.of(context).primaryColor,
          ),
          Text(
            isAgree ? '동의함' : '동의하지 않음',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // 공용 알림 다이얼로그
  void _showAlertDialog(
    String title,
    String content, {
    VoidCallback? onConfirm,
    VoidCallback? onClosed,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  onConfirm?.call(); // 추가 콜백 실행
                },
                child: const Text('확인'),
              ),
            ],
          ),
    ).then((_) => onClosed?.call()); // 다이얼로그가 닫힌 후 실행될 콜백
  }
}
