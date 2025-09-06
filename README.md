# Three-Tier-Web-Application - AWS  
Progetto AWS su Architettura a 3 livelli

# 📌 Documentazione

## 📖 Introduzione
Questo progetto utilizza Terraform per creare e gestire un’infrastruttura a 3 livelli su AWS, progettata per scalabilità, sicurezza e resilienza.
L’architettura include:
- **Networking**: VPC, Subnet pubbliche e private, IGW, NAT Gateway, Security Group, Route 53, Target Group 
- **Compute**: Application Load Balancer (ALB), Auto Scaling Group + EC2, AMI
- **Database**: Amazon RDS (MySQL) Multi-AZ con replica cross-region
- **Bilanciatori & Edge**: ALB e CloudFront per distribuzione globale
- **Storage/Content**:S3 per static assets e backup, CloudFront per caching e CDN
- **Sicurezza**: AWS WAF, ACM (SSL/TLS), KMS (encryption), IAM (least privilege)
- **Monitoring & DR**: AWS Backup, AWS Budget, CloudWatch (metriche e allarmi)
- **Messaggistica**: Amazon SNS per notifiche cross-region

## 🛠️ Requisiti
Prima di eseguire il progetto, assicurati di avere:
- **Terraform** installato (https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI** installato e configurato
- **Credenziali AWS** con permessi per creare risorse

## 🔧 Configurazione delle Variabili d'Ambiente
Per evitare di salvare le credenziali AWS nei file Terraform, utilizziamo **variabili d'ambiente**.

Esegui questi comandi nel terminale:
```sh
export AWS_ACCESS_KEY_ID="TUA_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="TUA_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-1"
```
Se vuoi rendere queste variabili permanenti, aggiungile al file `~/.bashrc` (Linux) o `~/.zshrc` (macOS):
```sh
echo 'export AWS_ACCESS_KEY_ID="TUA_ACCESS_KEY"' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY="TUA_SECRET_KEY"' >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION="us-east-1"' >> ~/.bashrc
source ~/.bashrc
```

## 📂 Struttura del Progetto
```
/terraform-project
 ├── Acm.tf         # Gestisce i certificati
 ├── Alb.tf    # Bilanciatore del carico 
 ├── Ami.tf      # Immagini AMI per Ec2
 ├── Asg.tf     # Creazione delle istanze EC2
 ├── Aws Budget.tf  # Imposta limite di spesa
 ├── Backup.tf    # Creazione di un bucket S3
 ├── Cloudfront.tf      # Gestione dei segreti AWS
 ├── Ec2.tf      # Output dei valori chiave
 ├── Iam.tf      # Gestione dei segreti AWS
 ├── Kms.tf      # Gestione dei segreti AWS
 ├── Launch_Template.tf      # Gestione dei segreti AWS
 ├── Main.tf      # Gestione dei segreti AWS
 ├── Providers.tf      # Gestione dei segreti AWS
 ├── RDS.tf      # Gestione dei segreti AWS
 ├── Route53.tf      # Gestione dei segreti AWS
 ├── S3.tf      # Gestione dei segreti AWS
 ├── Security Group.tf      # Gestione dei segreti AWS
 ├── Sns.tf      # Gestione dei segreti AWS
 ├── Target Group.tf      # Gestione dei segreti AWS
 ├── Terraform.tfvars.tf      # Gestione dei segreti AWS
 ├── Variables.tf      # Gestione dei segreti AWS
 ├── Vpc.tf      # Gestione dei segreti AWS
 ├── Waf.tf      # Gestione dei segreti AWS
 ├── .gitignore      # Evita di caricare file sensibili su GitHub
```

## 🚀 Deploy dell'Infrastruttura
Dopo aver configurato le variabili d’ambiente, esegui i seguenti comandi:

1. **Inizializza Terraform** (scarica i provider necessari)
   ```sh
   terraform init
   ```

2. **Visualizza il piano di esecuzione**
   ```sh
   terraform plan
   ```

3. **Applica le configurazioni**
   ```sh
   terraform apply
   ```

4. **Visualizza gli output**
   ```sh
   terraform output
   ```

## ❌ Pulizia delle Risorse
Se vuoi distruggere tutte le risorse create, esegui:
```sh
terraform destroy
```

## 🔒 File `.gitignore`
Per proteggere le credenziali e i file di stato, il file `.gitignore` deve includere:
```
terraform.tfvars
.terraform/
terraform.tfstate
terraform.tfstate.backup
```
