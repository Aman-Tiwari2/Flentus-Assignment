terraform{
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws"{
    region="eu-noth-1"
}


# Creating a VPC

resource "aws_vpc" "aman-tiwari-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "aman-tiwari-vpc"
  }
  
}

# Creating Public Subnet


resource "aws_subnet" "aman-tiwari-public-subnet1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.aman-tiwari-vpc.id
  tags = {
    Name = "aman-tiwari-public-subnet1"
  }
  
}

resource "aws_subnet" "aman-tiwari-public-subnet2" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.aman-tiwari-vpc.id
  tags = {
    Name = "aman-tiwari-public-subnet2"
  }
}


# Creating Private Subnet


resource "aws_subnet" "aman-tiwari-private-subnet1" {
  cidr_block = "10.0.5.0/24"
  vpc_id = aws_vpc.aman-tiwari-vpc.id
  tags = {
    Name = "aman-tiwari-private-subnet1"
  }
  
}

resource "aws_subnet" "aman-tiwari-private-subnet2" {
  cidr_block = "10.0.7.0/24"
  vpc_id = aws_vpc.aman-tiwari-vpc.id
  tags = {
    Name = "aman-tiwari-private-subnet2"
  }
}


# Creating InternetGateway


resource "aws_internet_gateway" "aman-tiwari-igw" {
  vpc_id = aws_vpc.aman-tiwari-vpc.id
  tags={
    Name = "aman-tiwari-igw"
  } 
}

# Creating Routing Table


resource "aws_route_table" "aman-tiwari-routing-table-public" {
  vpc_id = aws_vpc.aman-tiwari-vpc.id
  route = {
    cidr_block = "0.0.0.0/0",
    gateway_id = aws_internet_gateway.aman-tiwari-routing-table-public.id
  }
  tags = {
    Name = "aman-tiwari-routing-table-public"
  } 
}

# Associating Route table

resource "aws_route_table_association" "public-subnet1" {
  route_table_id = aws_route_table.aman-tiwari-routing-table-public.id
  subnet_id = aws_subnet.aman-tiwari-public-subnet1.id
}

resource "aws_route_table_association" "public-subnet1" {
  route_table_id = aws_route_table.aman-tiwari-routing-table-public.id
  subnet_id = aws_subnet.aman-tiwari-public-subnet2.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "aman-tiwari-ips"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "aman-tiwari-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aman-tiwari-private-rt"
  }
}

# Route: private subnets outbound → NAT Gateway
resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate Private Subnet 1
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate Private Subnet 2
resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}
