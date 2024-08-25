from typing import List

from django.core.mail import EmailMessage
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

    email = EmailMessage(
        "Anomalie déclarée",
        """Une nouvelle anomalie a été déclarée sur Rostrenen et moi.

        Adresse : {}
        Nom complet : {}
        Adresse email : {}
        Numéro de téléphone : {}
        Description :
        {}""".format(
            payload_dict["address"],
            payload_dict["full_name"],
            payload_dict["email"],
            payload_dict["phone_number"],
            payload_dict["description"],
        ),
        "rostrenen-et-moi@rostrenen.bzh",
        ["rostrenen-et-moi@rostrenen.bzh"],
    )
    for photo in photos:
        photo.seek(0)
        email.attach(photo.name, photo.read(), photo.content_type)
    email.send(fail_silently=False)

    return {"id": anomaly.id}
