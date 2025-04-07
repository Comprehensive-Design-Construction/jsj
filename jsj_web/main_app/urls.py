from django.urls import path
from . import views  # 현재 디렉터리에서 views를 가져옵니다

urlpatterns = [
    # 사용자가 루트 경로('')를 방문하면 index 뷰를 호출합니다
    path("", views.index, name="index"),
    path("create_customer/", views.create_customer_view, name="create_customer"),
]
