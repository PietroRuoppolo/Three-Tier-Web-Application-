AWS Three-Tier Architecture - Terraform

Progetto AWS Architettura a 3 Livelli (Web, App, DB)

📌 Documentazione del Progetto Terraform

📖 Introduzione

Questo progetto utilizza Terraform per creare un’infrastruttura a 3 livelli su AWS, con focus su scalabilità, sicurezza e disponibilità.
L’architettura include:

VPC con subnet pubbliche e private in più Availability Zones

Application Load Balancer (ALB) per bilanciare il traffico web

EC2 in Auto Scaling Group per livelli Web e App

RDS MySQL in configurazione Multi-AZ per il livello Database

S3 per static assets e backup

CloudFront per distribuzione globale con caching

Route 53 per DNS e failover

Sicurezza gestita con IAM, Security Groups e NACL

🛠️ Requisiti

Prima di eseguire il progetto, assicurati di avere:

Terraform
 installato

AWS CLI
 installata e configurata

Credenziali AWS con permessi per creare risorse (IAM Administrator consigliato)

🔧 Configurazione delle Variabili d'Ambiente

Per evitare di salvare credenziali sensibili nei file Terraform, usa variabili d’ambiente.

Esegui questi comandi nel terminale:

export AWS_ACCESS_KEY_ID="TUA_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="TUA_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-1"


Se vuoi renderle permanenti:

echo 'export AWS_ACCESS_KEY_ID="TUA_ACCESS_KEY"' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY="TUA_SECRET_KEY"' >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION="us-east-1"' >> ~/.bashrc
source ~/.bashrc

📂 Struttura del Progetto
/three-tier-aws
 ├── main.tf               # Configurazione principale
 ├── providers.tf          # Provider AWS e alias multi-region
 ├── variables.tf          # Dichiarazione variabili
 ├── vpc.tf                # Networking: VPC, subnet, IGW, NAT
 ├── security_groups.tf    # Configurazione Security Groups
 ├── alb.tf                # Application Load Balancer + Target Groups
 ├── asg.tf                # Auto Scaling Group + Launch Templates EC2
 ├── rds.tf                # Database RDS MySQL
 ├── s3.tf                 # Bucket S3 (backup, static assets, logs)
 ├── route53.tf            # DNS e Health Checks
 ├── cloudfront.tf         # Distribuzione CloudFront
 ├── outputs.tf            # Output dei valori chiave
 ├── terraform.tfvars      # Variabili personalizzate (NON caricare su GitHub)
 ├── .gitignore            # Esclude file sensibili e di stato

🚀 Deploy dell’Infrastruttura

Inizializza Terraform (scarica i provider):

terraform init


Visualizza il piano di esecuzione:

terraform plan


Applica le configurazioni:

terraform apply


Visualizza gli output:

terraform output

❌ Pulizia delle Risorse

Per distruggere tutte le risorse create:

terraform destroy

🔒 File .gitignore

Assicurati che il file .gitignore includa:

terraform.tfvars
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.pem
