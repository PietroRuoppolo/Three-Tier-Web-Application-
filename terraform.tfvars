# Coppia di chiavi EC2 (ssh key pair)
key_pair_name   = "temp-key"
public_key_path = "temp-key.pub" # oppure percorso assoluto se preferisci


# Certificato per il backend ALB (HTTPS). Se non serve, lascia vuoto.
backend_cert_arn = ""



##############################
# CloudFront dominio alternativo (CNAME)
##############################
cf_alt_domain = "threetier.ExampleDomain.club"

##############################
# Region DR (us‑west‑1)
##############################
aws_region_secondary = "us-west-1"

public_zone_id = "Z00286601MI189KA69B8H"
domain         = "ExampleDomain.club"

alerts_email = "lavoratoreonline12@gmail.com"

ce_service_monitor_arn = "arn:aws:ce::904233103130:anomalymonitor/d973d7a7-020c-40a5-801e-5f91260ae6e5"


