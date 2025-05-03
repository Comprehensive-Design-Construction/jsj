import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // 고유 ID 생성을 위해 추가 (pubspec.yaml에 uuid 패키지 추가 필요)

import '../../../core/utils/preferences_service.dart';
import '../../../data/models/added_person.dart';
import '../../../data/models/api/coordinates_response.dart'; // 좌표 응답 모델
import '../../../data/services/api_service.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final ApiService _apiService = ApiService();
  final PreferencesService _prefsService = PreferencesService();
  final _formKey = GlobalKey<FormState>(); // Form 위젯 사용 위한 키

  // 입력 컨트롤러 및 상태 변수
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate;
  List<String> _guList = []; // 구 목록
  String? _selectedGu; // 선택된 구
  List<String> _dongList = []; // 동 목록
  String? _selectedDong; // 선택된 동
  final Map<String, bool> _userTypeSelection = {
    // 사용자 특성 선택 상태
    '농촌': false,
    '비닐하우스': false,
    '실외작업자': false,
    // TODO: 필요한 다른 특성 추가 (예: 노인, 어린이 등 - 온보딩과 일관성 있게)
  };
  // TODO: 기저질환 입력 UI 및 상태 변수 추가

  // 로딩 및 에러 상태
  bool _isLoadingGu = false;
  bool _isLoadingDong = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGuData(); // 화면 시작 시 '구' 목록 불러오기
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // '구' 목록 불러오기
  Future<void> _fetchGuData() async {
    setState(() {
      _isLoadingGu = true;
      _errorMessage = null;
    });
    try {
      _guList = await _apiService.fetchGuList();
    } catch (e) {
      _errorMessage = '구 목록을 불러오는데 실패했습니다: $e';
      print(_errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoadingGu = false);
      }
    }
  }

  // 선택된 '구'에 해당하는 '동' 목록 불러오기
  Future<void> _fetchDongData(String selectedGu) async {
    setState(() {
      _isLoadingDong = true;
      _dongList = []; // 동 목록 초기화
      _selectedDong = null; // 동 선택 초기화
      _errorMessage = null;
    });
    try {
      _dongList = await _apiService.fetchDongList(selectedGu);
    } catch (e) {
      _errorMessage = '$selectedGu의 동 목록을 불러오는데 실패했습니다: $e';
      print(_errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoadingDong = false);
      }
    }
  }

  // 생년월일 선택 DatePicker (기존과 동일)
  void _presentDatePicker() {
    picker.DatePicker.showDatePicker(
      context,
      /* ... 설정 ... */
      onConfirm: (date) {
        setState(() {
          _selectedBirthDate = date;
        });
      },
      currentTime:
          _selectedBirthDate ??
          DateTime.now().subtract(Duration(days: 365 * 30)),
      locale: picker.LocaleType.ko,
      // ... 테마 ...
    );
  }

  // 나이 계산 (기존과 동일)
  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  // "추가하기" 버튼 로직
  Future<void> _addPerson() async {
    // 입력값 유효성 검사
    if (!(_formKey.currentState?.validate() ?? false)) return; // 이름 검증
    if (_selectedBirthDate == null) {
      _showErrorSnackBar('생년월일을 선택해주세요.');
      return;
    }
    if (_selectedGu == null) {
      _showErrorSnackBar('지역(구)을 선택해주세요.');
      return;
    }
    if (_selectedDong == null) {
      _showErrorSnackBar('지역(동)을 선택해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // 1. 위경도 좌표 조회
      final CoordinatesResponse coords = await _apiService.fetchCoordinates(
        _selectedGu!,
        _selectedDong!,
      );

      // 2. 저장할 데이터 준비
      final age = _calculateAge(_selectedBirthDate);
      final selectedTypes =
          _userTypeSelection.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
      // TODO: 기저질환 리스트 가져오기
      final List<String> diseaseParam = [...selectedTypes /*, ...diseases*/];

      // 3. AddedPerson 객체 생성 (고유 ID 생성)
      final newPerson = AddedPerson(
        id: Uuid().v4(), // UUID로 고유 ID 생성
        name: _nameController.text.trim(),
        birthDate: _selectedBirthDate,
        gu: _selectedGu,
        dong: _selectedDong,
        latitude: coords.latitude,
        longitude: coords.longitude,
        userTypes:
            diseaseParam.isNotEmpty
                ? diseaseParam
                : null, // 빈 리스트 대신 null 저장 가능
      );

      // 4. 로컬 저장소에 추가
      await _prefsService.addPerson(newPerson);

      // 5. 성공 처리 및 화면 닫기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newPerson.name}님이 추가되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true); // true를 반환하여 이전 화면에서 갱신 필요 알림
      }
    } catch (e) {
      // 오류 처리
      _errorMessage = '사람 추가 중 오류가 발생했습니다: $e';
      print(_errorMessage);
      _showErrorSnackBar(_errorMessage ?? '알 수 없는 오류 발생');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 에러 메시지 SnackBar 표시 헬퍼
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사람 추가'),
        leading: IconButton(
          icon: const Icon(Icons.close), // 닫기 아이콘
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        // 입력 유효성 검사를 위해 Form 위젯 사용
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 이름 ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '이름 *',
                  hintText: '추가할 사람의 이름을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  // 이름 필수 입력 검증
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // --- 생년월일 ---
              TextButton.icon(
                icon: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.grey[700],
                ),
                label: Text(
                  _selectedBirthDate == null
                      ? '생년월일 선택 *'
                      : DateFormat('yyyy년 MM월 dd일').format(_selectedBirthDate!),
                  style: TextStyle(
                    color:
                        _selectedBirthDate == null
                            ? Colors.grey[600]
                            : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  foregroundColor: Colors.black87, // 아이콘 색상
                ),
                onPressed: _presentDatePicker,
              ),
              const SizedBox(height: 24),

              // --- 지역 선택 ---
              Text('거주 지역 *', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              // 구 선택 드롭다운
              DropdownButtonFormField<String>(
                value: _selectedGu,
                hint: Text(_isLoadingGu ? '불러오는 중...' : '구를 선택하세요'),
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items:
                    _guList.map((String gu) {
                      return DropdownMenuItem<String>(
                        value: gu,
                        child: Text(gu),
                      );
                    }).toList(),
                onChanged:
                    _isLoadingGu
                        ? null
                        : (String? newValue) {
                          if (newValue != null && newValue != _selectedGu) {
                            setState(() {
                              _selectedGu = newValue;
                              _selectedDong = null; // 구 변경 시 동 선택 초기화
                              _dongList = []; // 동 목록 초기화
                            });
                            _fetchDongData(newValue); // 동 목록 불러오기
                          }
                        },
                validator: (value) => value == null ? '구를 선택해주세요.' : null,
              ),
              const SizedBox(height: 12),
              // 동 선택 드롭다운
              DropdownButtonFormField<String>(
                value: _selectedDong,
                // 구가 선택되었고 로딩 중이 아니면 활성화, 아니면 비활성화
                hint: Text(
                  _isLoadingDong
                      ? '불러오는 중...'
                      : (_selectedGu == null ? '구를 먼저 선택하세요' : '동을 선택하세요'),
                ),
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items:
                    _dongList.map((String dong) {
                      return DropdownMenuItem<String>(
                        value: dong,
                        child: Text(dong),
                      );
                    }).toList(),
                onChanged:
                    (_selectedGu == null || _isLoadingDong)
                        ? null
                        : (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedDong = newValue);
                          }
                        },
                validator:
                    (value) =>
                        (_selectedGu != null && value == null)
                            ? '동을 선택해주세요.'
                            : null,
              ),
              const SizedBox(height: 24),

              // --- 사용자 특성 ---
              Text(
                '사용자 특성 (중복 선택 가능)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._userTypeSelection.keys.map((String key) {
                return CheckboxListTile(
                  /* ... (Onboarding과 동일) ... */
                  title: Text(
                    key,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: _userTypeSelection[key],
                  onChanged: (bool? value) {
                    setState(() {
                      _userTypeSelection[key] = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true, // 좀 더 컴팩트하게
                  activeColor: Colors.blueAccent,
                );
              }).toList(),
              const SizedBox(height: 24),

              // --- 기저질환 Placeholder ---
              Text('기저질환 (선택)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                /* ... (Placeholder 내용) ... */
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '향후 기저질환 선택 기능이 추가될 예정입니다.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 40),

              // --- 추가하기 버튼 ---
              ElevatedButton(
                onPressed: _isSaving ? null : _addPerson, // 저장 중 비활성화
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                        : const Text('추가하기'),
              ),

              // --- 에러 메시지 표시 ---
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
