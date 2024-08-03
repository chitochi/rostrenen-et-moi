from typing import List

from django.db import transaction
from ninja import File, Form, ModelSchema, NinjaAPI, UploadedFile

from .models import Anomaly


class AnomalyInput(ModelSchema):
    class Meta:
        model = Anomaly
        fields = [
            "address",
            "description",
            "full_name",
            "email",
            "phone_number",
        ]


api = NinjaAPI()


@api.post("/anomalies")
@transaction.atomic
def create_anomaly(
    request, payload: Form[AnomalyInput], photos: List[UploadedFile] = File([])
):
    payload_dict = payload.dict()
    anomaly = Anomaly.objects.create(**payload_dict)
    for photo in photos:
        anomaly.photo_set.create(photo=photo)
    return {"id": anomaly.id}
