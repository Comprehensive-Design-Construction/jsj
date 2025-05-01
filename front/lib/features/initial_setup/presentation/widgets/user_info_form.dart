// lib/features/initial_setup/presentation/widgets/user_info_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅 위해 추가 (pubspec.yaml에 intl 추가 필요)

// 기저 질환 목록 (예시 - 실제 앱에 맞게 수정)
const List<String> availableDiseases = ['고혈압', '당뇨', '심장질환', '호흡기질환', '기타'];

class UserInfoForm extends StatefulWidget {
  // 폼 제출 시 호출될 콜백 함수
  final Function(
    String? name,
    DateTime? dob,
    String? gender,
    List<String> diseases,
  )
  onSubmit;
  // 간편 시작 시 호출될 콜백 함수
  final VoidCallback onSkip;

  const UserInfoForm({super.key, required this.onSubmit, required this.onSkip});

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final _formKey = GlobalKey<FormState>(); // 폼 상태 관리를 위한 키

  // 입력 컨트롤러
  final _nameController = TextEditingController();

  // 선택된 값 관리
  DateTime? _selectedDob; // 선택된 생년월일
  String? _selectedGender; // 선택된 성별
  final List<String> _selectedDiseases = []; // 선택된 기저질환 목록

  @override
  void dispose() {
    _nameController.dispose(); // 컨트롤러 정리
    super.dispose();
  }

  // 생년월일 선택 다이얼로그 표시
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(), // 초기 날짜
      firstDate: DateTime(1900), // 선택 가능 최소 날짜
      lastDate: DateTime.now(), // 선택 가능 최대 날짜
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey, // 폼 키 연결
      child: ListView(
        // 긴 폼 스크롤 가능하도록 ListView 사용
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 이름 입력 ---
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '이름 (선택)',
              hintText: '이름을 입력하세요',
              border: OutlineInputBorder(),
            ),
            // 이름은 필수가 아님
          ),
          const SizedBox(height: 16),

          // --- 생년월일 입력 ---
          InkWell(
            // 탭 가능하도록 InkWell 사용
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '생년월일 (선택)',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _selectedDob == null
                    ? '날짜를 선택하세요'
                    : DateFormat(
                      'yyyy-MM-dd',
                    ).format(_selectedDob!), // intl 패키지 사용
                style: TextStyle(
                  color: _selectedDob == null ? Colors.grey[600] : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 성별 선택 ---
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: '성별 (선택)',
              border: OutlineInputBorder(),
            ),
            hint: const Text('성별을 선택하세요'),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('남성')),
              DropdownMenuItem(value: 'female', child: Text('여성')),
              // 필요시 'other' 또는 '미선택' 옵션 추가
            ],
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
            // validator: (value) => value == null ? '성별을 선택해주세요.' : null, // 필수가 아님
          ),
          const SizedBox(height: 24),

          // --- 기저 질환 선택 ---
          Text(
            '기저 질환 (해당하는 것을 모두 선택하세요)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            // Chip들을 가로로 배치하고 공간이 부족하면 다음 줄로 넘김
            spacing: 8.0, // 가로 간격
            runSpacing: 4.0, // 세로 간격
            children:
                availableDiseases.map((disease) {
                  final isSelected = _selectedDiseases.contains(disease);
                  return FilterChip(
                    label: Text(disease),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedDiseases.add(disease);
                        } else {
                          _selectedDiseases.remove(disease);
                        }
                      });
                    },
                    selectedColor:
                        Theme.of(context).primaryColorLight, // 선택 시 배경색
                  );
                }).toList(),
          ),
          const SizedBox(height: 32),

          // --- 버튼 ---
          ElevatedButton(
            onPressed: () {
              // 현재는 유효성 검사 없이 제출 (이름, 생년월일, 성별은 선택사항)
              // if (_formKey.currentState!.validate()) {
              //   _formKey.currentState!.save(); // 필수가 아니므로 save는 불필요할 수 있음
              // }
              widget.onSubmit(
                _nameController.text.isEmpty ? null : _nameController.text,
                _selectedDob,
                _selectedGender,
                _selectedDiseases,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('시작하기'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            // 간편 시작 버튼
            onPressed: widget.onSkip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('간편 시작 (정보 입력 안 함)'),
          ),
        ],
      ),
    );
  }
}
