# ─────────────────────────────────────────────────────────────────────────────
# terraform.tfvars – valori per le variabili obbligatorie
# Inserisci qui le info specifiche del tuo ambiente; Terraform le caricherà
# automaticamente e non ti chiederà più input a runtime.
# ─────────────────────────────────────────────────────────────────────────────

##############################
# Credenziali e chiavi
##############################
# Password RDS (NON committare in git se il repo è pubblico!)
db_password = "Rodman00!"

# Coppia di chiavi EC2 (ssh key pair)
key_pair_name   = "temp-key"
public_key_path = "temp-key.pub" # oppure percorso assoluto se preferisci

##############################
# Certificati ACM
##############################
# Certificato per il backend ALB (HTTPS). Se non serve, lascia vuoto.
backend_cert_arn = ""

/*# Certificato per CloudFront (deve essere in us‑east‑1, valido per cf_alt_domain)
cloudfront_cert_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"*/

##############################
# CloudFront dominio alternativo (CNAME)
##############################
cf_alt_domain = "threetier.pietroruoppolo.club"

##############################
# Region DR (us‑west‑1)
##############################
aws_region_secondary = "us-west-1"

public_zone_id = "Z00286601MI189KA69B8H" # <-- se è questa ad essere delegata
domain         = "pietroruoppolo.club"

alerts_email = "ruoppolo46@gmail.com"

ce_service_monitor_arn = "arn:aws:ce::904233103130:anomalymonitor/d973d7a7-020c-40a5-801e-5f91260ae6e5"
