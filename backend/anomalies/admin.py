from django.contrib import admin

from .models import Anomaly, Photo


class PhotoInline(admin.StackedInline):
    model = Photo
    extra = 0


@admin.register(Anomaly)
class AnomalyAdmin(admin.ModelAdmin):
    date_hierarchy = "created_at"
    list_display = ["__str__", "address", "created_at"]
    inlines = [
        PhotoInline,
    ]
