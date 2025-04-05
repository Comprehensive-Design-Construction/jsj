from django.shortcuts import render


# Create your views here.
def index(request):
    """
    메인 홈페이지 템플릿을 렌더링합니다.
    """
    context = {}  # 필요하다면 여기에 데이터를 담아 템플릿으로 전달할 수 있습니다
    return render(request, "main_app/index.html", context)
