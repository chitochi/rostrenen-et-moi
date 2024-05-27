from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("anomalies/", include("anomalies.urls")),
    path("admin/", admin.site.urls),
]
