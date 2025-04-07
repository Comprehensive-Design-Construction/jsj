from django.shortcuts import render, redirect
from .models import Customer  # Customer 모델 import


# Create your views here.
def index(request):
    """
    메인 홈페이지 템플릿을 렌더링합니다.
    """
    context = {}  # 필요하다면 여기에 데이터를 담아 템플릿으로 전달할 수 있습니다
    return render(request, "main_app/index.html", context)


def create_customer_view(request):
    """
    POST 요청으로 받은 고객 정보를 저장하는 뷰
    """
    if request.method == "POST":
        # POST 데이터에서 정보 추출
        full_name = request.POST.get("full_name")
        birth = request.POST.get("birth")
        condition_icon = request.POST.get("condition_icon")
        condition_details = request.POST.get("condition_details")
        address = request.POST.get("address")

        # 간단한 유효성 검사 (이름과 생년월일은 필수라고 가정)
        if full_name and birth:
            # Customer 객체 생성 및 저장
            customer = Customer(
                full_name=full_name,
                birth=birth,
                condition_icon=condition_icon,
                condition_details=condition_details,
                address=address,
            )
            customer.save()
            # 저장 후 메인 페이지로 리디렉션
            return redirect("index")  # urls.py에 정의된 'index' URL 이름 사용
        else:
            # 필수 정보 누락 시 (간단히 메인 페이지로 리디렉션, 실제로는 오류 메시지 전달 권장)
            return redirect("index")
    else:
        # GET 요청 등 다른 메소드 요청 시 메인 페이지로 리디렉션
        return redirect("index")
