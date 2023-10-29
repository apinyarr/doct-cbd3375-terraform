terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.57.0"
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

module "k8s_fe_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "k8s-fe-vpc"
  cidr = "192.168.30.0/26"

  azs             = ["ca-central-1a", "ca-central-1b"]
  private_subnets = ["192.168.30.0/28", "192.168.30.16/28"]
  public_subnets  = ["192.168.30.32/28", "192.168.30.48/28"]

  enable_nat_gateway = var.activate_nat_gateway
  single_nat_gateway = var.activate_nat_gateway
  one_nat_gateway_per_az = false
  enable_vpn_gateway = false
  map_public_ip_on_launch = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "k8s_services_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "k8s-services-sg"
  description = "Security group for K8s services"
  vpc_id      = module.k8s_fe_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "http"
      cidr_blocks = "170.133.228.85/32"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh"
      cidr_blocks = "170.133.228.85/32"
    },
  ]

  egress_with_cidr_blocks = [
    {
        rule        = "all-all"
        cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "doct_cbd3375_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "cbd3375-eks-cluster"
  cluster_version = "1.27"

  cluster_endpoint_public_access  = true


  vpc_id                   = module.k8s_fe_vpc.vpc_id
  subnet_ids               = [module.k8s_fe_vpc.private_subnets[0], module.k8s_fe_vpc.private_subnets[1]]
  control_plane_subnet_ids = [module.k8s_fe_vpc.public_subnets[0], module.k8s_fe_vpc.public_subnets[1]]

  # Self Managed Node Group(s)
  # self_managed_node_group_defaults = {
  #   instance_type                          = "m6i.large"
  #   update_launch_template_default_version = true
  #   iam_role_additional_policies = {
  #     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  #   }
  # }

  # self_managed_node_groups = {
  #   one = {
  #     name         = "mixed-1"
  #     max_size     = 5
  #     desired_size = 2

  #     use_mixed_instances_policy = true
  #     mixed_instances_policy = {
  #       instances_distribution = {
  #         on_demand_base_capacity                  = 0
  #         on_demand_percentage_above_base_capacity = 10
  #         spot_allocation_strategy                 = "capacity-optimized"
  #       }

  #       override = [
  #         {
  #           instance_type     = "m5.large"
  #           weighted_capacity = "1"
  #         },
  #         {
  #           instance_type     = "m6i.large"
  #           weighted_capacity = "2"
  #         },
  #       ]
  #     }
  #   }
  # }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.micro"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t2.micro"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
    }
  }

  # aws-auth configmap

  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:aws:iam::66666666666:role/role1"
  #     username = "role1"
  #     groups   = ["system:masters"]
  #   },
  # ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::698017650344:user/andy"
      username = "andy"
      groups   = ["system:masters"]
    },
    # {
    #   userarn  = "arn:aws:iam::66666666666:user/user2"
    #   username = "user2"
    #   groups   = ["system:masters"]
    # },
  ]

  # aws_auth_accounts = [
  #   "777777777777",
  #   "888888888888",
  # ]

  tags = {
    Environment = "prd"
    Terraform   = "true"
  }
}