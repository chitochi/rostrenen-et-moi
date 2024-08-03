from django.db import models
from django.db.models import Q
from phonenumber_field.modelfields import PhoneNumberField


class Photo(models.Model):
    photo = models.ImageField()
    anomaly = models.ForeignKey(
        "Anomaly",
        on_delete=models.CASCADE,
    )

    def __str__(self):
        return self.photo.name


class Anomaly(models.Model):
    created_at = models.DateTimeField(
        "Créée le",
        auto_now_add=True,
    )
    address = models.CharField(
        "Adresse",
        max_length=200,
    )
    description = models.TextField(
        max_length=1000,
    )
    full_name = models.CharField(
        "Nom complet",
        max_length=100,
    )
    phone_number = PhoneNumberField(
        "Numéro de téléphone",
        blank=True,
        null=True,
    )
    email = models.EmailField(
        "Adresse email",
        blank=True,
        null=True,
    )

    class Meta:
        verbose_name = "anomalie"
        constraints = [
            models.CheckConstraint(
                check=Q(phone_number=None, email__isnull=False)
                | Q(email=None, phone_number__isnull=False)
                | Q(email__isnull=False, phone_number__isnull=False),
                name="one of phone_number and email must be not null",
            ),
        ]

    def __str__(self):
        return f"Anomalie n°{self.pk}"
