# jsj
hi

### 공지사항
Chromedriver => 환경 변수 등록하고 webdriver_manager이랑 shutil로 관리합니다.
github에 올리지 말아주세여

1. C:\Program Files (x86)\Google\Chrome\Application에 chromedriver.exe를 넣습니다.
2. 환경변수 => path => C:\Program Files (x86)\Google\Chrome\Application 입력
3. pip install webdriver_manager
4. service = Service(shutil.which("chromedriver"))
   driver = webdriver.Chrome(service=service) {options 파라미터 가능}

잘 모르겠으면 편하게 물어봐주세요 ~~