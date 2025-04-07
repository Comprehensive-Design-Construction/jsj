from django.db import models

# Create your models here.


class Customer(models.Model):
    full_name = models.CharField(max_length=100)
    birth = models.CharField(max_length=100)  # 날짜 형식은 CharField로 간단히 처리
    condition_icon = models.CharField(
        max_length=10, blank=True
    )  # 선택 사항이므로 blank=True
    condition_details = models.CharField(max_length=200, blank=True)
    address = models.CharField(max_length=200, blank=True)
    # avatar = models.ImageField(upload_to='avatars/', blank=True) # 이미지 필드는 추후 구현

    def __str__(self):
        return self.full_name
