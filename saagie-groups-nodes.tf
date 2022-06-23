# EKS Node Groups
resource "aws_eks_node_group" "saagi-estiam-eks_cluster_nodes_group" {
  cluster_name    = aws_eks_cluster.saagi-estiam-eks_cluster.name
  node_group_name = "saagi-estiam" 
  node_role_arn   = aws_iam_role.saagie-estiam-node-role.arn
  subnet_ids      = [aws_subnet.saagi-estiam-vpc-private-subnet.id]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  ami_type       = "AL2_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM
  capacity_type  = "ON_DEMAND"  # ON_DEMAND, SPOT
  disk_size      = 300 #espace disque de 300 Go
  instance_types = ["m5.xlarge"]

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-eks_cluster_nodes_group"
    }

  depends_on = [
    aws_iam_role_policy_attachment.saagi-estiam-eks_cluster_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.saagi-estiam-eks_cluster_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.saagi-estiam-eks_cluster_nodes_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# EKS Node Security Group
resource "aws_security_group" "saagi-estiam-eks_cluster_nodes_sg" {
  name        = "saagi-estiam-eks_cluster_nodes_sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.saagi-estiam-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-eks_cluster_nodes_sg"
    }
}

# EKS Node IAM Role
resource "aws_iam_role" "saagie-estiam-node-role" {
  name = "saagie-estiam-node-role"

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
    ]
  })  
}

resource "aws_iam_role_policy_attachment" "saagi-estiam-eks_cluster_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.saagie-estiam-node-role.name
}

resource "aws_iam_role_policy_attachment" "saagi-estiam-eks_cluster_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.saagie-estiam-node-role.name
}

resource "aws_iam_role_policy_attachment" "saagi-estiam-eks_cluster_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.saagie-estiam-node-role.name
}

resource "aws_security_group_rule" "saagi-estiam-eks_cluster_nodes_internal_sg" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.saagi-estiam-eks_cluster_nodes_sg.id
  source_security_group_id = aws_security_group.saagi-estiam-eks_cluster_nodes_sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "saagi-estiam-eks_cluster_nodes_inbound_sg" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.saagi-estiam-eks_cluster_nodes_sg.id
  source_security_group_id = aws_security_group.saagi-estiam-eks_cluster_sg.id
  to_port                  = 65535
  type                     = "ingress"
}