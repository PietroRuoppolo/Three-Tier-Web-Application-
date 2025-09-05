AWS Three-Tier Architecture

Progetto AWS Architettura a 3 Livelli (Web, App, DB)

📌 Documentazione del Progetto Terraform
📖 Introduzione

Questo progetto utilizza Terraform per creare e gestire un’infrastruttura a 3 livelli su AWS, con focus su scalabilità, sicurezza e resilienza.

L’architettura include:

Networking: VPC, Subnet (pubbliche/private), IGW, NAT, Security Group, Route 53, Target Group

Compute: Application Load Balancer (ALB), Auto Scaling Group + EC2 (web/app, Node.js/Express), AMI

Database: Amazon RDS (MySQL) in Multi-AZ

Bilanciamento & Edge: ALB, CloudFront

Storage/Content: S3 per backup e static assets, CloudFront per distribuzione globale

Sicurezza: WAF, ACM (certificati SSL), KMS (encryption), IAM

Monitoring & Disaster Recovery: AWS Backup, AWS Budget

Messaggistica: SNS per notifiche

🛠️ Requisiti

Prima di eseguire il progetto, assicurati di avere:

Terraform installato → Download

AWS CLI installato e configurato → Guida

Credenziali AWS con permessi sufficienti (IAM Administrator consigliato)

🔧 Configurazione delle Variabili d'Ambiente

Per evitare di salvare le credenziali AWS nei file Terraform, utilizziamo variabili d'ambiente.

Esegui questi comandi nel terminale:

export AWS_ACCESS_KEY_ID="TUA_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="TUA_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-1"


Se vuoi renderle permanenti, aggiungile a ~/.bashrc (Linux) o ~/.zshrc (macOS):

echo 'export AWS_ACCESS_KEY_ID="TUA_ACCESS_KEY"' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY="TUA_SECRET_KEY"' >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION="us-east-1"' >> ~/.bashrc
source ~/.bashrc

📂 Struttura del Progetto
/three-tier-aws
 ├── main.tf               # Configurazione principale di Terraform
 ├── providers.tf          # Provider AWS e alias multi-region
 ├── variables.tf          # Dichiarazione delle variabili
 ├── vpc.tf                # Networking: VPC, subnet, IGW, NAT
 ├── security_groups.tf    # Security Groups e NACL
 ├── alb.tf                # Application Load Balancer + Target Groups
 ├── asg.tf                # Auto Scaling Group + Launch Templates
 ├── rds.tf                # Database RDS MySQL
 ├── s3.tf                 # Bucket S3 per backup e contenuti
 ├── route53.tf            # DNS con Route 53
 ├── cloudfront.tf         # Distribuzione globale con CloudFront
 ├── waf.tf                # AWS WAF e regole
 ├── kms.tf                # KMS per crittografia
 ├── sns.tf                # Notifiche SNS
 ├── backup.tf             # AWS Backup (policy e vault)
 ├── budgets.tf            # AWS Budget per cost monitoring
 ├── outputs.tf            # Output dei valori chiave
 ├── terraform.tfvars      # Variabili personalizzate (NON caricare su GitHub)
 ├── .gitignore            # Esclude file sensibili e di stato

🚀 Deploy dell'Infrastruttura

Dopo aver configurato le variabili d’ambiente, esegui i seguenti comandi:

Inizializza Terraform

terraform init


Visualizza il piano di esecuzione

terraform plan


Applica le configurazioni

terraform apply


Visualizza gli output

terraform output

❌ Pulizia delle Risorse

Per distruggere tutte le risorse create:

terraform destroy

🔒 File .gitignore

Il file .gitignore deve includere:

terraform.tfvars
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.pem
