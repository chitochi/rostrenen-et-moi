from django.contrib import admin
from import_export import resources
from import_export.admin import ImportExportModelAdmin

from .models import Anomaly, Photo


class AnomalyResource(resources.ModelResource):
    class Meta:
        model = Anomaly


class PhotoInline(admin.StackedInline):
    model = Photo
    extra = 0


@admin.register(Anomaly)
class AnomalyAdmin(ImportExportModelAdmin):
    resource_classes = [AnomalyResource]
    date_hierarchy = "created_at"
    list_display = ["__str__", "address", "created_at"]
    inlines = [
        PhotoInline,
    ]
