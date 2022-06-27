# terraform to create ECS cluster

# create a VPC for the cluster

resource "aws_vpc" "webapp_vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "webappVPC"
  }
}

# create a subnet for the cluster
resource "aws_subnet" "webapp_subnet" {
  vpc_id                  = aws_vpc.webapp_vpc.id
  cidr_block              = "10.1.0.0/20"
  map_public_ip_on_launch = true
  tags = {
    Name = "webapp_subnet"
  }
}

# ECS requires internet connectivity. I've configured an Internet Gateway
# but you can also use a NAT Gateway or VPC Endpoint. 
resource "aws_internet_gateway" "webapp_igw" {
  vpc_id = aws_vpc.webapp_vpc.id

  tags = {
    Name = "webapp_igw"
  }
}

# route table that directs traffic to the IGW
resource "aws_default_route_table" "webapp_default_rtbl" {
  default_route_table_id = aws_vpc.webapp_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp_igw.id
  }
  tags = {
    Name = "webapp_def_route"
  }  
}

# create a cluster 
resource "aws_ecs_cluster" "testwebapp" {
  name = "testwebapp"
  tags = {
    "billingtag" = "workrelated"
  }
}

# declare the capacity provider type, in this case FARGATE
resource "aws_ecs_cluster_capacity_providers" "webappcapprov" {
  cluster_name = aws_ecs_cluster.testwebapp.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}

# create a task
# the definition of the container it runs are in the webapp.json file
resource "aws_ecs_task_definition" "webapptask" {
  family                = "webapptask"
  container_definitions = data.template_file.json_webapp_def.rendered
  cpu                   = 256
  memory                = 512
  network_mode          = "awsvpc"
  tags = {
    billingtag = "workrelated"
  }
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = "arn:aws:iam::317976261112:role/webappTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::317976261112:role/webappTaskExecutionRole"
  runtime_platform {
    operating_system_family = "LINUX"
  }
}

data "template_file" "json_webapp_def" {
    template = file("step2/webapp.json")
    vars = {
        REPONAME = "${var.reponame}"
        CONTAINERNAME = "${var.containername}"
    }
}

# define a service to run the task
resource "aws_ecs_service" "weabappservice" {
  name                    = "webappservice"
  cluster                 = aws_ecs_cluster.testwebapp.id
  task_definition         = aws_ecs_task_definition.webapptask.arn
  desired_count           = 1
  enable_ecs_managed_tags = true
  wait_for_steady_state   = false
  launch_type             = "FARGATE"
  network_configuration {
    assign_public_ip = true
    security_groups = [
      aws_security_group.webappsecgrp.id
    ]
    subnets = [
      aws_subnet.webapp_subnet.id
    ]
  }
}

# iam role for the task to use
resource "aws_iam_role" "webapptaskrole" {
  name               = "webappTaskExecutionRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#  policies to attach to iam role 
resource "aws_iam_role_policy" "ecs_policies" {
    name = "webappEcsPolicies"
    role = aws_iam_role.webapptaskrole.name
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# security group for the service to use
resource "aws_security_group" "webappsecgrp" {
  name        = "webapp-secgrp"
  description = "2022-03-28T19:20:35.764Z"
  vpc_id      = aws_vpc.webapp_vpc.id
  ingress = [
    {
      description      = "inbound to container app"
      from_port        = 5000
      to_port          = 5000
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
