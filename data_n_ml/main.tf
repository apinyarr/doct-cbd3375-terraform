terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.44.0"
    }
  }

  required_version = ">= 1.3.7"

  # Uncomment after creating the bucket
  # backend "s3" {
  #   bucket = "tfstate-bucket"
  #   key    = "terraform/state/bootstrap"
  #   region = "${var.region}"
  # }
}

module "data_ml_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "data-ml-sg"
  description = "Security group for Data and ML server"
  # vpc_id      = module.ops_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh"
      cidr_blocks = "208.98.222.122/32"
    },
    # {
    #   from_port   = 3389
    #   to_port     = 3389
    #   protocol    = "tcp"
    #   description = "rdp"
    #   cidr_blocks = "170.133.228.85/32"
    # },
  ]

  egress_with_cidr_blocks = [
    {
        rule        = "all-all"
        cidr_blocks = "0.0.0.0/0"
    },
  ]
}

resource "aws_iam_policy" "data_ml_policy" {
  name        = "data_ml_policy"
  description = "data_ml_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:CopyObject",
        "s3:HeadObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::dataset-3375-2",
        "arn:aws:s3:::dataset-3375-2/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "data_ml_role" {
  name = "data-ml-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "terraform_ec2_iam_policy" {
  role = "${aws_iam_role.data_ml_role.id}"
  policy_arn = "${aws_iam_policy.data_ml_policy.arn}"
}

resource "aws_iam_instance_profile" "data_ml_ec2_profile" {
  name = "data_ml_ec2_profile"
  role = aws_iam_role.data_ml_role.name
}

module "ec2_data_ml" {
  create = var.create_data_ml_server

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.4"

  name = "ec2_data_ml"

  ami                    = "ami-0ea18256de20ecdfc"
  iam_instance_profile   = aws_iam_instance_profile.data_ml_ec2_profile.name
  instance_type          = "t2.micro"
  key_name               = "andy-key"
  monitoring             = true

  vpc_security_group_ids = [module.data_ml_sg.security_group_id]
  # subnet_id              = module.pre_vpc.public_subnets[0]
  user_data              = "${file("./scripts/host_preparation.sh")}"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}