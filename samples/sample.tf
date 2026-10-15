# Sample Terraform file for checking theme colors.
// Line comment, alternate style
/* Block
   comment */

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-tf-state"
    key    = "envs/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_count" {
  type    = number
  default = 2

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    public  = { cidr = "10.0.1.0/24", az = "us-east-1a" }
    private = { cidr = "10.0.2.0/24", az = "us-east-1b" }
  }
}

locals {
  name_prefix = "demo-${terraform.workspace}"
  common_tags = {
    Project     = "theme-test"
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
  ports      = [22, 80, 443]
  is_prod    = terraform.workspace == "prod" ? true : false
  upper_name = upper(local.name_prefix)
  cidrs      = [for s in var.subnets : s.cidr]
  az_by_name = { for k, v in var.subnets : k => v.az if v.az != null }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${local.name_prefix}-${each.key}"
  }
}

resource "aws_security_group" "web" {
  name   = "${local.name_prefix}-web"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.is_prod ? "t3.large" : "t3.micro"
  subnet_id     = aws_subnet.this["public"].id
  monitoring    = var.enable_monitoring

  user_data = <<-EOT
    #!/bin/bash
    echo "Hello from ${local.name_prefix}-${count.index}" > /var/www/index.html
  EOT

  depends_on = [aws_security_group.web]

  tags = {
    Name = format("%s-web-%02d", local.name_prefix, count.index + 1)
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket = lower("${local.name_prefix}-assets")
  acl    = null
}

output "instance_ips" {
  description = "Public IPs of the web instances"
  value       = aws_instance.web[*].public_ip
  sensitive   = false
}

output "summary" {
  value = jsonencode({
    vpc     = aws_vpc.main.id
    subnets = length(aws_subnet.this)
    tags    = try(local.common_tags["Project"], "none")
  })
}
