############################
# Provider AWS – default (prod)
############################
############################
# Provider AWS – primario (alias)
############################
provider "aws" {
  alias  = "primary"
  region = var.aws_region_primary # stessa regione del default
}

############################
# Provider AWS – secondario / DR (alias)
############################
provider "aws" {
  alias  = "secondary"
  region = var.aws_region_secondary # es. us-west-2
}
# Global services (Cost Explorer / Budgets / CloudFront / Route 53 metrics)
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}
