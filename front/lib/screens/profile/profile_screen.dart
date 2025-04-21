import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/constants/app_constants.dart';
import '../../providers/user_profile_provider.dart'; // 사용자 프로필 프로바이더

/// 사용자 건강 정보(나이, 질환)를 입력/수정하는 화면
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // 폼 상태 관리를 위한 GlobalKey
  final _formKey = GlobalKey<FormState>();
  // 나이 입력 컨트롤러
  final _ageController = TextEditingController();
  // 선택 가능한 질병 목록 (실제 앱에서는 설정 또는 API에서 가져올 수 있음)
  final List<String> _availableDiseases = AppConstants.availableDiseases;
  // 현재 사용자가 선택한 질병 목록 상태 변수
  List<String> _selectedDiseases = [];

  @override
  void initState() {
    super.initState();
    // 위젯 초기화 시, 프로바이더에서 현재 프로필 정보를 읽어와 폼에 설정
    final profile = ref.read(userProfileProvider); // read: 초기값 로드용 (watch 아님)
    if (profile.age != null) {
      _ageController.text = profile.age.toString();
    }
    // 리스트는 복사하여 사용 (원본 상태 직접 수정 방지)
    _selectedDiseases = List.from(profile.disease);
  }

  @override
  void dispose() {
    // 컨트롤러 리소스 해제
    _ageController.dispose();
    super.dispose();
  }

  /// 입력된 정보 저장 처리
  void _saveProfile() {
    // 폼 유효성 검사
    if (_formKey.currentState!.validate()) {
      // 나이 텍스트를 정수로 변환 (실패 시 null)
      final age = int.tryParse(_ageController.text);
      // 프로바이더의 updateProfile 메서드 호출하여 상태 업데이트
      ref
          .read(userProfileProvider.notifier)
          .updateProfile(
            age: age, // 변환된 정수 또는 null 전달
            disease: _selectedDiseases, // 현재 선택된 질병 목록 전달
          );
      // 이전 화면으로 돌아가기
      if (mounted) Navigator.pop(context);
      // 사용자에게 저장 완료 피드백 표시 (SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('건강 정보가 업데이트되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 입력 정보 초기화 처리
  void _clearProfile() {
    setState(() {
      _ageController.clear();
      _selectedDiseases.clear();
    });
    // 프로바이더 상태 초기화
    ref.read(userProfileProvider.notifier).clearProfile();
    // 사용자에게 초기화 완료 피드백 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('건강 정보가 초기화되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 빌드 시점의 프로필 상태를 다시 읽어와 질병 선택 상태 동기화 (선택 사항)
    // final currentProfile = ref.watch(userProfileProvider);
    // _selectedDiseases = List.from(currentProfile.disease);

    return Scaffold(
      appBar: AppBar(title: const Text('건강 정보 입력')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // 긴 내용 스크롤 가능하도록 ListView 사용
            children: [
              // 나이 입력 필드
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: '나이 (선택 사항)',
                  // border: OutlineInputBorder(), // 테마에서 정의된 스타일 사용
                  // suffixIcon: Icon(Icons.cake_outlined)
                ),
                keyboardType: TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ), // 숫자 키패드 (양수만)
                validator: (value) {
                  // 유효성 검사: 입력값이 있고, 유효한 숫자 범위(0~120)가 아니면 에러 메시지 반환
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 0 || age > 120) {
                      return '0세 이상 120세 이하 유효한 나이를 입력해주세요.';
                    }
                  }
                  return null; // 유효하거나 비어있으면 null 반환
                },
              ),
              const SizedBox(height: 24),

              // 보유 질환 선택 섹션
              Text(
                '보유 질환 (다중 선택 가능, 선택 사항)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Wrap 위젯: 자식 위젯(ChoiceChip)들이 공간에 맞춰 자동 줄바꿈
              Wrap(
                spacing: 8.0, // 가로 간격
                runSpacing: 4.0, // 세로 간격
                children:
                    _availableDiseases.map((disease) {
                      // 각 질병에 대한 선택칩 생성
                      return ChoiceChip(
                        label: Text(disease),
                        labelStyle: TextStyle(
                          color:
                              _selectedDiseases.contains(disease)
                                  ? Theme.of(context).primaryColor
                                  : Colors.black54,
                          fontWeight:
                              _selectedDiseases.contains(disease)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                        selected: _selectedDiseases.contains(
                          disease,
                        ), // 현재 선택 상태 반영
                        onSelected: (selected) {
                          // 선택 상태 변경 시 setState 호출하여 UI 업데이트
                          setState(() {
                            if (selected) {
                              _selectedDiseases.add(disease);
                            } else {
                              _selectedDiseases.remove(disease);
                            }
                          });
                        },
                        // 선택 시 배경색/테두리 (테마에서 일부 설정됨)
                        selectedColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        side:
                            _selectedDiseases.contains(disease)
                                ? BorderSide(
                                  color: Theme.of(context).primaryColor,
                                )
                                : BorderSide(color: Colors.grey.shade400),
                        // checkmarkColor: Theme.of(context).primaryColor, // 체크 아이콘 색상 (선택 사항)
                        showCheckmark: false, // 기본 체크 아이콘 숨김 (선택 사항)
                      );
                    }).toList(),
              ),
              const SizedBox(height: 32),

              // 저장 버튼
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('저장하기'),
                onPressed: _saveProfile, // 저장 함수 연결
                // style: ElevatedButton.styleFrom(...) // 테마에서 정의된 스타일 사용
              ),
              const SizedBox(height: 12),
              // 초기화 버튼
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('정보 초기화'),
                onPressed: _clearProfile, // 초기화 함수 연결
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ), // 강조색상
              ),
            ],
          ),
        ),
      ),
    );
  }
}
