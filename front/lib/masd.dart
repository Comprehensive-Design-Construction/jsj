import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: UserFormPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();

  String? selectedGu;
  String? selectedDong;
  String? selectedCondition;
  String? selectedExtra;

  final Map<String, List<String>> seoulDistricts = {
    "강남구": ["역삼동", "삼성동", "청담동", "논현동", "대치동", "도곡동", "세곡동", "수서동", "일원동"],
    "강동구": ["천호동", "성내동", "길동", "둔촌동", "암사동", "명일동", "고덕동", "상일동"],
    "강북구": ["미아동", "번동", "수유동", "우이동"],
    "강서구": ["화곡동", "등촌동", "염창동", "가양동", "방화동", "마곡동", "공항동"],
    "관악구": ["신림동", "봉천동", "남현동"],
    "광진구": ["자양동", "화양동", "구의동", "중곡동", "군자동"],
    "구로구": ["구로동", "가리봉동", "고척동", "개봉동", "오류동", "궁동", "항동"],
    "금천구": ["가산동", "독산동", "시흥동"],
    "노원구": ["중계동", "하계동", "상계동", "월계동"],
    "도봉구": ["방학동", "창동", "도봉동"],
    "동대문구": ["용두동", "신설동", "제기동", "전농동", "답십리동", "장안동", "휘경동", "이문동"],
    "동작구": ["노량진동", "상도동", "대방동", "사당동", "흑석동"],
    "마포구": ["공덕동", "도화동", "아현동", "망원동", "성산동", "연남동", "합정동", "서교동"],
    "서대문구": ["충정로", "북아현동", "홍제동", "연희동", "남가좌동", "북가좌동"],
    "서초구": ["서초동", "방배동", "반포동", "잠원동"],
    "성동구": ["왕십리", "금호동", "행당동", "사근동", "응봉동", "성수동"],
    "성북구": ["성북동", "정릉동", "돈암동", "길음동", "장위동", "석관동"],
    "송파구": ["잠실동", "신천동", "방이동", "오륜동", "풍납동", "가락동", "문정동", "장지동", "거여동", "마천동"],
    "양천구": ["목동", "신월동", "신정동"],
    "영등포구": ["영등포동", "여의도동", "당산동", "문래동", "신길동", "양평동"],
    "용산구": ["이태원동", "한남동", "후암동", "남영동", "청파동", "보광동"],
    "은평구": ["녹번동", "불광동", "갈현동", "역촌동", "응암동", "구산동", "대조동", "신사동", "증산동", "수색동", "진관동"],
    "종로구": ["청운동", "신교동", "숭인동", "혜화동", "사직동", "평창동"],
    "중구": ["충무로", "명동", "남산동", "필동", "을지로"],
    "중랑구": ["면목동", "상봉동", "중화동", "묵동", "망우동", "신내동"],
  };

  final List<String> conditions = ["없음", "고혈압"];
  final List<String> extras = ["없음", "임산부", "노인"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.add_circle_outline, color: Colors.black),
        title: const Text('추가', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.menu, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              formLabel("이름"),
              textField(nameController, "Name"),

              const SizedBox(height: 16),
              formLabel("생년월일(ex. 1999.01.01)"),
              textField(birthController, "1990.01.01"),

              const SizedBox(height: 20),
              formLabel("지역(구)"),
              dropDownMenu(
                selectedGu,
                seoulDistricts.keys.toList(),
                (value) {
                  setState(() {
                    selectedGu = value;
                    selectedDong = null;
                  });
                },
              ),

              const SizedBox(height: 20),
              formLabel("지역(동)"),
              dropDownMenu(
                selectedDong,
                selectedGu != null ? seoulDistricts[selectedGu!] ?? [] : [],
                (value) {
                  setState(() {
                    selectedDong = value;
                  });
                },
              ),

              const SizedBox(height: 20),
              formLabel("기저질환 / 추가사항"),
              dropDownMenu(selectedCondition, conditions, (value) {
                setState(() {
                  selectedCondition = value;
                });
              }),

              const SizedBox(height: 20),
              formLabel("추가사항"),
              dropDownMenu(selectedExtra, extras, (value) {
                setState(() {
                  selectedExtra = value;
                });
              }),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("추가 하기", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: 14,
      ),
    );
  }

  Widget textField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget dropDownMenu(String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) {
          return DropdownMenuItem(value: e, child: Text(e));
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white, // 흰색 배경
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        dropdownColor: Colors.white, // 드롭다운도 흰색
      ),
    );
  }
}