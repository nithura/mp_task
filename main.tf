
#vpc and subnet details 
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Environment" = var.environment_tag
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Environment" = var.environment_tag
  }
}

resource "aws_subnet" "subnet_public-1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_subnet-1a
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone
  tags = {
    "Environment" = var.environment_tag
  }
}

resource "aws_subnet" "subnet_public-1b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_subnet-1b
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone
  tags = {
    "Environment" = var.environment_tag
  }
}


resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Environment" = var.environment_tag
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = [aws_subnet.subnet_public1a.id, aws_subnet.subnet_public1b.id]
  route_table_id = aws_route_table.rtb_public.id
}


### EC2 instance and security group details 
resource "aws_security_group" "ssh_access" {
  name   = "ssh_access"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Environment" = var.environment_tag
  }
}



resource "aws_key_pair" "ec2key" {
  key_name   = "publicKey"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "ec2-instance" {
  count                  = 3
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = [aws_subnet.subnet_public1a.id, aws_subnet.subnet_public1b.id]
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  key_name               = aws_key_pair.ec2key.key_name

  tags = {
    "Environment" = var.environment_tag
  }
}

### ALB details 
resource "aws_security_group" "http_sg_alb" {
  name   = "http_sg_alb"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Environment" = ${var.environment_tag}-alb
  }
}


# Create a new application load balancer.
resource "aws_alb" "alb" {
  name            = "terraform-alb"
  security_groups = [aws_security_group.ssh_access.id]
  subnets         = [aws_subnet.subnet_public1a.id, aws_subnet.subnet_public1b.id]

  tags {
    Name = "terraform-alb"
  }
}

# Create a new target group for the application load balancer.
resource "aws_alb_target_group" "group" {
  name     = "terraform-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path = "/"
    port = 80
  }
}

# Create a new application load balancer listener for HTTP.
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}