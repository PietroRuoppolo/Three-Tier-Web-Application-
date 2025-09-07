# Three-Tier-Web-Application - AWS  
Progetto AWS su Architettura a 3 livelli

# 📌 Documentazione

## 📖 Introduzione
Questo progetto è pensato per creare e gestire un’infrastruttura a 3 livelli su AWS, progettata per scalabilità, sicurezza e resilienza.
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
 ├── Cloudfront.tf      # CDN che distribuisce i contenuti con bassa latenza
 ├── Ec2.tf      # Macchine Virtuali
 ├── Iam.tf      # Ruoli e policy per dare permessi alle risorse)
 ├── Kms.tf      # Chiavi di cifratura per dati in S3, RDS, EBS
 ├── Launch_Template.tf      # Definisce come avviare le istanze: AMI, tipo, user_data
 ├── Main.tf      # File principale che richiama e collega le risorse
 ├── Providers.tf      # Specifica il provider Cloud da utilizzare e la regione
 ├── RDS.tf      # Crea un Database gestito
 ├── Route53.tf      # Gestisce i record DNS per i domini
 ├── S3.tf      # Crea Bucket per file, log, siti statici, backup
 ├── Security Group.tf      # Regole firewall: chi può accedere e su quali porte
 ├── Sns.tf      # Invia notifiche via email o SMS
 ├── Target Group.tf      # Insieme di istanze su cui l’ALB manda il traffico
 ├── Terraform.tfvars.tf      # Dove inserisci i parametri reali, es. nome VPC, password DB
 ├── Variables.tf      # Dichiarazione delle variabili con tipo e descrizione
 ├── Vpc.tf      # Crea rete, subnet, gateway e routing
 ├── Waf.tf      # Regole di protezione contro attacchi web
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
