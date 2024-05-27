from django.db import models


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

    class Meta:
        verbose_name = "anomalie"

    def __str__(self):
        return f"Anomalie n°{self.pk}"
