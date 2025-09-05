# SecOps & Governance - AWS  
Progetto AWS su SecOps &amp; Governance 

# 📌 Documentazione del Progetto Terraform

## 📖 Introduzione
Questo progetto utilizza **Terraform** per creare e gestire risorse su **AWS**, tra cui:
- **VPC** con subnet pubbliche e private
- **Istanza EC2**
- **S3 Bucket per i backup**
- **Gestione dei segreti con AWS Secrets Manager**
- **Sicurezza con IAM, Security Groups e Route Tables**

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
 ├── main.tf         # Configurazione principale di Terraform
 ├── variables.tf    # Dichiarazione delle variabili
 ├── network.tf      # Configurazione di VPC e subnet
 ├── istances.tf     # Creazione delle istanze EC2
 ├── iam.tf          # Configurazione IAM (ruoli e policy)
 ├── s3_bucket.tf    # Creazione di un bucket S3
 ├── secrets.tf      # Gestione dei segreti AWS
 ├── outputs.tf      # Output dei valori chiave
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
