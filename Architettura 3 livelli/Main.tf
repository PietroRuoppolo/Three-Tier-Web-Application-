terraform {
  required_version = ">= 1.7.0"
}
provider "aws" {
  alias  = "west"
  region = "us-west-2"
  # facoltativo, se usi un profilo diverso
  # profile = "my-aws-profile"
}

# providers.tf
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


terraform {
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 5.0" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
    time  = { source = "hashicorp/time", version = "~> 0.10" }
  }
}

# Region "di lavoro" (quella del tuo stack)
# Assicurati che questa variabile esista (o adattala al tuo naming)
variable "domain_name" {
  type    = string
  default = "pietroruoppolo.club"
}

# Assicurati che contact esista e che phone sia già nel formato +39.333XXXXXXX
# (se lo hai già definito altrove, lascia quello ed elimina questa variabile)
variable "contact" {
  type = object({
    first_name : string
    last_name : string
    address_line1 : string
    city : string           # es. "Torino"
    state_province : string # es. "TO"  (SIGLA PROVINCIA)
    country_code : string   # es. "IT"
    zip : string
    phone : string # es. "+39.3330000000"  <-- PUNTO OBBLIGATORIO
    email : string
  })
  default = {
    first_name     = "Pietro"
    last_name      = "Ruoppolo"
    address_line1  = "Via Strada 12"
    city           = "Torino"
    state_province = "TO"
    country_code   = "IT"
    zip            = "10100"
    phone          = "+39.3330000000" # <-- IMPORTANTE: con il punto
    email          = "ruoppolo46@gmail.com"
  }
}

locals {
  register_domain_json = jsonencode({
    DomainName      = var.domain_name
    DurationInYears = 1
    AutoRenew       = true

    AdminContact = {
      ContactType  = "PERSON"
      FirstName    = var.contact.first_name
      LastName     = var.contact.last_name
      AddressLine1 = var.contact.address_line1
      City         = var.contact.city
      State        = var.contact.state_province # "TO"
      CountryCode  = var.contact.country_code
      ZipCode      = var.contact.zip
      PhoneNumber  = var.contact.phone # "+39.333...."
      Email        = var.contact.email
    }

    RegistrantContact = {
      ContactType  = "PERSON"
      FirstName    = var.contact.first_name
      LastName     = var.contact.last_name
      AddressLine1 = var.contact.address_line1
      City         = var.contact.city
      State        = var.contact.state_province
      CountryCode  = var.contact.country_code
      ZipCode      = var.contact.zip
      PhoneNumber  = var.contact.phone
      Email        = var.contact.email
    }

    TechContact = {
      ContactType  = "PERSON"
      FirstName    = var.contact.first_name
      LastName     = var.contact.last_name
      AddressLine1 = var.contact.address_line1
      City         = var.contact.city
      State        = var.contact.state_province
      CountryCode  = var.contact.country_code
      ZipCode      = var.contact.zip
      PhoneNumber  = var.contact.phone
      Email        = var.contact.email
    }

    BillingContact = {
      ContactType  = "PERSON"
      FirstName    = var.contact.first_name
      LastName     = var.contact.last_name
      AddressLine1 = var.contact.address_line1
      City         = var.contact.city
      State        = var.contact.state_province
      CountryCode  = var.contact.country_code
      ZipCode      = var.contact.zip
      PhoneNumber  = var.contact.phone
      Email        = var.contact.email
    }

    PrivacyProtectAdminContact      = true
    PrivacyProtectRegistrantContact = true
    PrivacyProtectTechContact       = true
  })
}




resource "local_file" "register_domain_json" {
  filename = "${path.module}/register-domain.json"
  content  = local.register_domain_json
}
# 1) REGISTRAZIONE dominio — solo se "AVAILABLE"
resource "null_resource" "register_domain" {
  triggers = {
    domain_name = var.domain_name
    json_hash   = sha1(local.register_domain_json)
  }

  provisioner "local-exec" {
    # PowerShell nativo su Windows
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = "Stop"
      $domain = "${var.domain_name}"
      $avail = (aws route53domains check-domain-availability --region us-east-1 --domain-name $domain | ConvertFrom-Json).Availability
      if ($avail -eq "AVAILABLE") {
        Write-Host ">> Registrazione dominio $domain..."
        aws route53domains register-domain --region us-east-1 --cli-input-json file://register-domain.json | Out-Null
      } else {
        Write-Host ">> Dominio $domain già registrato o non disponibile (stato: $avail). Salto la registrazione."
      }
    EOT
  }

  depends_on = [local_file.register_domain_json]
}

# 2) ATTESA finché il dominio risulta "UNAVAILABLE" (cioè registrato e visibile)
resource "null_resource" "wait_domain_registered" {
  triggers = {
    domain_name = var.domain_name
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = "Stop"
      $domain = "${var.domain_name}"
      for ($i=0; $i -lt 60; $i++) { # max ~30 minuti (60 x 30s)
        $avail = (aws route53domains check-domain-availability --region us-east-1 --domain-name $domain | ConvertFrom-Json).Availability
        if ($avail -ne "AVAILABLE") { Write-Host ">> Dominio $domain ora risulta $avail. OK."; exit 0 }
        Start-Sleep -Seconds 30
      }
      Write-Error "Dominio ancora AVAILABLE dopo l'attesa. Riprova più tardi o verifica l'email di validazione del registrar."
    EOT
  }

  depends_on = [null_resource.register_domain]
}

# 3) Hosted Zone pubblica
resource "aws_route53_zone" "public" {
  name       = var.domain_name
  depends_on = [null_resource.wait_domain_registered]
}


output "nameservers_to_set" {
  description = "Se il passaggio NS fallisse, imposta manualmente questi NS presso il registrar."
  value       = aws_route53_zone.public.name_servers
}
