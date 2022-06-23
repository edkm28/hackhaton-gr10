#####  NETWORK INFRASTRUCTURE  ########

# Create VPC
resource "aws_vpc" "saagi-estiam-vpc" {
  cidr_block = "10.0.0.0/16" # Adresse de réseau pour les instances EC2 et EKS (14 machines)

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur      = "DNEDTB"
        Name        = "saagi-estiam-vpc"
    }
}

# Définition de la passerelle internet (Internet Gateway, IGW)
resource "aws_internet_gateway" "saagi-estiam-internet-gateway" {
  vpc_id = aws_vpc.saagi-estiam-vpc.id

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur      = "DNEDTB"
        Name        = "saagi-estiam-internet-gateway"
  }

  depends_on = [aws_vpc.saagi-estiam-vpc]
}

# Création du sous-réseau publique
resource "aws_subnet" "saagi-estiam-vpc-public-subnet" {
  
  vpc_id            = aws_vpc.saagi-estiam-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur      = "DNEDTB"
        Name        = "saagi-estiam-vpc-public-subnet"

        "kubernetes.io/role/elb"                         = 1        # ajout d'un équillibreur de charge public
        "kubernetes.io/cluster/saagi-estiam-eks_cluster" = "shared" # ajout du sous-réseau public à l'équillibreur de charge public
    }

  map_public_ip_on_launch = true  
}

# Création du sous-réseau privé
resource "aws_subnet" "saagi-estiam-vpc-private-subnet" {
  
  vpc_id            = aws_vpc.saagi-estiam-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3b"

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur      = "DNEDTB"
        Name        = "saagi-estiam-vpc-private-subnet"

        "kubernetes.io/role/internal-elb"                = 1        # ajout d'un équillibreur de charge interne
        "kubernetes.io/cluster/saagi-estiam-eks_cluster" = "shared" # ajout du sous-réseau public à l'équillibreur de charge interne
    }

}


# Définition des tables de routages

# Ajout d'une route autorisant le traffic sortant du sous-réseau public via IGW
resource "aws_route_table" "saagi-estiam-route_table" {
  vpc_id = aws_vpc.saagi-estiam-vpc.id

  route { # Tout traffic du sous-réseau publix est autorisé à aller sur internet
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.saagi-estiam-internet-gateway.id
  }

   tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur      = "DNEDTB"
        Name        = "saagi-estiam-route_table"
  }
}

# Association du sous-réseau public à la table de routage
resource "aws_route_table_association" "saagi-estiam-internet_access" {
  subnet_id      = aws_subnet.saagi-estiam-vpc-public-subnet.id
  route_table_id = aws_route_table.saagi-estiam-route_table.id
}

# Demande d'une addresse Elastic IP
resource "aws_eip" "saagi-estiam-eip" {
  vpc = true

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur      = "DNEDTB"
        Name        = "saagi-estiam-eip"
  }
}

# Définition d'une passerelle NAT (NAT Gateway) permettant aux noeuds du cluster 
# d'envoyer du traffic internet et de ne pas être accessible via l'internet
resource "aws_nat_gateway" "saagi-estiam-nat_gateway" {
  allocation_id = aws_eip.saagi-estiam-eip.id
  subnet_id     = aws_subnet.saagi-estiam-vpc-public-subnet.id

   tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-nat_gateway"
  }
}

# Ajout d'une route dans la table de routage pour la passerelle NAT
resource "aws_route" "saagi-estiam-route" {
  route_table_id         = aws_vpc.saagi-estiam-vpc.default_route_table_id
  nat_gateway_id         = aws_nat_gateway.saagi-estiam-nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

# Définition du groupe de sécurité pour le sous-réseau publique
resource "aws_security_group" "saagi-estiam-public_sg" {
  name   =  "saagi-estiam-public_sg"
  vpc_id = aws_vpc.saagi-estiam-vpc.id

   tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-public_sg"
  }
}

# Définition du groupe de sécurité pour la gestion du traffic sur le réseau publique
resource "aws_security_group_rule" "saagi-estiam-ingress_public_443_sg" {
  security_group_id = aws_security_group.saagi-estiam-public_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "saagi-estiam-ingress_public_80_sg" {
  security_group_id = aws_security_group.saagi-estiam-public_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "saagi-estiam-egress_public_sg" {
  security_group_id = aws_security_group.saagi-estiam-public_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Définition du groupe de sécurité pour le data plane
resource "aws_security_group" "saagi-estiam-data_plane_sg" {
  name   =  "saagi-estiam-data_plane_Worker-sg"
  vpc_id = aws_vpc.saagi-estiam-vpc.id

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-data_plane_Worker-sg"
  }
}

# Définition du groupe de sécurité pour les noeuds du cluster
resource "aws_security_group_rule" "saagi-estiam-nodes_sg" {
  description       = "Allow nodes to communicate with each other"
  security_group_id = aws_security_group.saagi-estiam-data_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["10.0.1.0/24", "10.0.2.0/24"]
}

resource "aws_security_group_rule" "saagi-estiam-nodes_inbound_sg" {
  description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id = aws_security_group.saagi-estiam-data_plane_sg.id
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24", "10.0.2.0/24"]
}

resource "aws_security_group_rule" "saagi-estiam-node_outbound_sg" {
  security_group_id = aws_security_group.saagi-estiam-data_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Définition du groupe de sécurité pour le control plane
resource "aws_security_group" "saagi-estiam-control_plane_sg" {
  name   = "saagi-estiam-control_plane_sg"
  vpc_id = aws_vpc.saagi-estiam-vpc.id

  tags = {
        Terraform   = "true"
        Environment = "dev"
        auteur = "DNEDTB"
        Name = "saagi-estiam-control_plane_sg"
  }
}

# Définition du groupe de sécurité pour la gestion du traffic pour le control plane
resource "aws_security_group_rule" "saagi-estiam-control_plane_inbound" {
  security_group_id = aws_security_group.saagi-estiam-control_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24", "10.0.2.0/24"]
}

resource "aws_security_group_rule" "saagi-estiam-control_plane_outbound" {
  security_group_id = aws_security_group.saagi-estiam-control_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
