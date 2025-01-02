from django.urls import path
from process import views

urlpatterns = [
    path("request/", views.CameraRequest, name="camera_request"),
]