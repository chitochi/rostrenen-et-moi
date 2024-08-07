# Generated by Django 5.0.7 on 2024-08-03 16:49

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        (
            "anomalies",
            "0002_anomaly_email_anomaly_full_name_anomaly_phone_number_and_more",
        ),
    ]

    operations = [
        migrations.RemoveConstraint(
            model_name="anomaly",
            name="one of phone_number and email must be not null",
        ),
        migrations.AddConstraint(
            model_name="anomaly",
            constraint=models.CheckConstraint(
                check=models.Q(
                    models.Q(("email__isnull", False), ("phone_number", None)),
                    models.Q(("email", None), ("phone_number__isnull", False)),
                    models.Q(("email__isnull", False), ("phone_number__isnull", False)),
                    _connector="OR",
                ),
                name="one of phone_number and email must be not null",
            ),
        ),
    ]
