# -----------------------------------------------------------------------------
# S3 Bucket for Private Artifacts & Telemetry
# -----------------------------------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "private_storage" {
  bucket        = "${var.environment}-airgapped-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "${var.environment}-airgapped-artifacts"
    Description = "Private storage accessed strictly via S3 Gateway Endpoint"
  }
}

resource "aws_s3_bucket_public_access_block" "private_storage" {
  bucket = aws_s3_bucket.private_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_storage" {
  bucket = aws_s3_bucket.private_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# 1. VPC Module (Zero Egress, Isolated Subnets)
# -----------------------------------------------------------------------------
module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = var.vpc_cidr
  isolated_subnet_cidrs = var.isolated_subnet_cidrs
  availability_zones    = var.availability_zones
  environment           = var.environment
}

# -----------------------------------------------------------------------------
# 2. VPC Endpoints Module (PrivateLink Interface & S3 Gateway)
# -----------------------------------------------------------------------------
module "endpoints" {
  source          = "./modules/endpoints"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = module.vpc.vpc_cidr_block
  subnet_ids      = module.vpc.subnet_ids
  route_table_ids = [module.vpc.route_table_id]
  aws_region      = var.aws_region
  environment     = var.environment
}

# -----------------------------------------------------------------------------
# 3. IAM Module (Roles & Least-Privilege Policies)
# -----------------------------------------------------------------------------
module "iam" {
  source        = "./modules/iam"
  environment   = var.environment
  s3_bucket_arn = aws_s3_bucket.private_storage.arn
}

# -----------------------------------------------------------------------------
# 4. Compute Module (EC2 in Isolated Subnet with SSM)
# -----------------------------------------------------------------------------
module "compute" {
  source               = "./modules/compute"
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr_block
  subnet_id            = module.vpc.subnet_ids[0]
  instance_type        = var.instance_type
  iam_instance_profile = module.iam.ec2_instance_profile_name
  s3_bucket_name       = aws_s3_bucket.private_storage.bucket
  environment          = var.environment

  depends_on = [
    module.endpoints
  ]
}

# -----------------------------------------------------------------------------
# 5. Lambda Module (VPC-Attached Network Sentinel)
# -----------------------------------------------------------------------------
module "lambda" {
  source          = "./modules/lambda"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = module.vpc.vpc_cidr_block
  subnet_ids      = module.vpc.subnet_ids
  lambda_role_arn = module.iam.lambda_role_arn
  s3_bucket_name  = aws_s3_bucket.private_storage.bucket
  environment     = var.environment

  depends_on = [
    module.endpoints
  ]
}
