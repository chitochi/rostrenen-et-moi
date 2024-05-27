# Generated by Django 5.0.5 on 2024-05-27 11:41

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="Anomaly",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                (
                    "created_at",
                    models.DateTimeField(auto_now_add=True, verbose_name="Créée le"),
                ),
                ("address", models.CharField(max_length=200, verbose_name="Adresse")),
                ("description", models.TextField(max_length=1000)),
            ],
            options={
                "verbose_name": "anomalie",
            },
        ),
        migrations.CreateModel(
            name="Photo",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("photo", models.ImageField(upload_to="")),
                (
                    "anomaly",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        to="anomalies.anomaly",
                    ),
                ),
            ],
        ),
    ]
