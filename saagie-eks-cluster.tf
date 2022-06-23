# EKS Cluster
resource "aws_eks_cluster" "saagi-estiam-eks_cluster" {
  name     = "saagi-estiam-eks_cluster"
  role_arn = aws_iam_role.saagi-estiam-eks_cluster_role.arn
  version  = "1.21"
  
  vpc_config {
    subnet_ids              = [aws_subnet.saagi-estiam-vpc-public-subnet.id, aws_subnet.saagi-estiam-vpc-private-subnet.id] 
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-eks_cluster"
    }

  depends_on = [
    aws_iam_role_policy_attachment.saagi-estiam-eks_cluster_role_AmazonEKSClusterPolicy
  ]
}

# EKS Cluster IAM Role
resource "aws_iam_role" "saagi-estiam-eks_cluster_role" {
  name = "saagi-estiam-eks_cluster_role"
  
   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        },
      },
    ]
  })  
}

resource "aws_iam_role_policy_attachment" "saagi-estiam-eks_cluster_role_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.saagi-estiam-eks_cluster_role.name
}

# EKS Cluster Security Group
resource "aws_security_group" "saagi-estiam-eks_cluster_sg" {
  name        = "saagi-estiam-eks_cluster_sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.saagi-estiam-vpc.id

tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-eks_cluster_sg"
    }
}

resource "aws_security_group_rule" "saagi-estiam-eks_cluster_inbound_sg" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.saagi-estiam-eks_cluster_sg.id
  source_security_group_id = aws_security_group.saagi-estiam-eks_cluster_nodes_sg.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "saagi-estiam-eks_cluster_outbound_sg" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.saagi-estiam-eks_cluster_sg.id
  source_security_group_id = aws_security_group.saagi-estiam-eks_cluster_nodes_sg.id
  to_port                  = 65535
  type                     = "egress"
}

# aws eks describe-cluster  --name saagi-estiam-eks_cluster  --query cluster.identity.oidc.issuer  --output text
# https://oidc.eks.eu-west-3.amazonaws.com/id/8D46AA41CAC19C2BF721F88AE8602C5E   issuer_url
# oidc.eks.eu-west-3.amazonaws.com/id/8D46AA41CAC19C2BF721F88AE8602C5E issuer_hostpath
# 984163881352  account_id
# arn:aws:iam::984163881352:oidc-provider/oidc.eks.eu-west-3.amazonaws.com/id/8D46AA41CAC19C2BF721F88AE8602C5E  provider_arn

# Saagie IAM Role for Saagie's job
resource "aws_iam_role" "saagi-estiam-saagie_job_role" {
  name = "saagi-estiam-saagie_job_role"
  
   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        },
      },
    ]
  })  
}