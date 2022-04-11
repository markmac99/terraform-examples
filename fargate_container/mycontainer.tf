# 
# terraform to create a docker container on AWS
#
#data used by the code in several places
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# variables to define the container and image
variable "reponame" { default = "myimage"}
variable "containername" {default = "mycontainer"}
variable "cicd_bucket" { default = "mjmm-cicd-bucket"}

# encryption/decryption key in the AWS KMS keystore
resource "aws_kms_key" "container_key" {
    description = "My KMS Key"
}

# bucket to store the code and artefacts in
resource "aws_s3_bucket" "cicd_bucket" {
  bucket = var.cicd_bucket
  force_destroy = true
}
# folder on the bucket to store artefacts in 
resource "aws_s3_object" "image_base_fldr" {
  bucket = aws_s3_bucket.cicd_bucket.id
  acl    = "private"
  key    = "/${var.containername}/image/"
  kms_key_id = "${aws_kms_key.container_key.arn}"
  #source = "/dev/null"
}

# create an ECR repository for the images
resource "aws_ecr_repository" "myimage" {
  name                 = var.reponame
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM role to allow codebuild to be executed
resource "aws_iam_role" "container_codebuild_role" {
  name = "codebuild_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# policy to attach to the codebuild role to allow it to
# - access the S3 bucket
# - create and update logs
# - access ECR and ECS resources
# - execute codebuild jobs
# - launch containers
resource "aws_iam_role_policy" "container_codebuild_policy" {
  name   = "container_codebuild_policy"
  role   = "${aws_iam_role.container_codebuild_role.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    { 
        "Effect": "Allow",
        "Action": [
            "s3:List*",
            "s3:HeadBucket",
            "s3:Describe*",
            "s3:Get*",
            "s3:PutObject*"
        ],
        "Resource": [
            "${aws_s3_bucket.cicd_bucket.arn}", 
            "${aws_s3_bucket.cicd_bucket.arn}${aws_s3_object.image_base_fldr.id}*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ecr:GetAuthorizationToken",
            "ecr:DescribeRepositories",
            "ecs:ListClusters",
            "ecs:DescribeClusters",
            "ecs:ListTasks",
            "ecs:DescribeTasks",
            "ecs:ListTaskDefinitions", 
            "ecs:ListTaskDefinitionFamilies",
            "ecs:DescribeTaskDefinition",
            "ecs:ListServices",
            "ecs:ListAccountSettings",
            "ecs:ListContainerInstances"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ecr:BatchCheckLayerAvailability", 
            "ecr:GetDownladUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
        ],
        "Resource": "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.reponame}*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "codebuild:GetResourcePolicy",
            "codebuild:StopBuild",
            "codebuild:StartBuild",
            "codebuild:UpdateProject",
            "codebuild:BatchGetBuilds",
            "codebuild:BatchGetProjects",
            "codebuild:InvalidateProjectCache"
        ],
        "Resource": "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.containername}*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterfaces",
            "ec2:DescribeSubnets", 
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
            "codebuild:ListBuilds",
            "codebuild:ListRepositories",
            "codebuild:ListCuratedEnvironmentImages",
            "codebuild:ListProjects"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:ListKeys",
            "kms:GenerateRandom",
            "kms:ListAliases",
            "kms:DescribeKey",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*"
        ],
        "Resource": [ "${aws_kms_key.container_key.arn}"]        
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:CreateNetworkInterfacePermission"
        ],
        "Resource": "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
        "Condition": {
            "StringEquals": {
                "ec2:Subnet": [
                    "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*"
                ],
                "ec2:AuthorizedService": "codebuild.amazonaws.com"
            }
        }
    }
  ]
}
EOF
}

# Create a null resource containing a list of the source files to be zipped
# This is set as a dependency of the zipfile and forces terraform to refresh
# the zip file every time one of the objects changes. 
resource "null_resource" "step1" {
  triggers = {
    main    = "${base64sha256(file("step1/Dockerfile"))}"
    handler = "${base64sha256(file("step1/app.py"))}"
#    lambdh = "${base64sha256(file("step1/lambda_function.py"))}"
    bsfile  = "${base64sha256(file("step1/buildspec.yml"))}"
  }
}

# create a zip file from the source code
data "archive_file" "codebuild-img-zip" {
    type = "zip"
    source_dir = "${path.root}/step1/"
    output_path = "${path.root}/${var.containername}.zip"
    depends_on = [null_resource.step1]
}

# this uploads the zip file
resource "aws_s3_object" "codebuild-img-zip-upl" {
    key =  "${aws_s3_object.image_base_fldr.id}code/${var.containername}.zip"
    bucket = "${aws_s3_bucket.cicd_bucket.id}"
    source = "${data.archive_file.codebuild-img-zip.output_path}"
    #content = filebase64("${data.archive_file.codebuild-img-zip.output_path}")
    kms_key_id = "${aws_kms_key.container_key.arn}"
}

# create the codebuild project 
resource "aws_codebuild_project" "myproject" {
    name = "${var.containername}"
    source {
        type=  "S3"
        location =  "${aws_s3_bucket.cicd_bucket.arn}${aws_s3_object.image_base_fldr.id}code/${var.containername}.zip"
        insecure_ssl = false
    }
    artifacts {
        type =  "S3"
        location = "${aws_s3_bucket.cicd_bucket.arn}"
        path = "${aws_s3_object.image_base_fldr.id}artifacts/"
        name = "testBuildArtefacts"
        packaging = "NONE"
    }
    environment {
        type = "LINUX_CONTAINER"
        image = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
        compute_type = "BUILD_GENERAL1_SMALL"
        privileged_mode = true
        environment_variable {
            name = "AWS_ACCOUNT_ID"
            value = "${data.aws_caller_identity.current.account_id}"
        } 
        environment_variable {
            name = "AWS_REGION"
            value = "${data.aws_region.current.name}"
        } 
        environment_variable {
            name = "REPONAME"
            value = "${var.reponame}"
        } 
    }
    service_role = "${aws_iam_role.container_codebuild_role.arn}"
    build_timeout = 60
    queued_timeout = 480
    encryption_key = "${aws_kms_key.container_key.arn}"
    #tags = {}
    logs_config {
        cloudwatch_logs {
            status =  "ENABLED"
        }
        s3_logs {
            status = "DISABLED"
            encryption_disabled = false
        }
    }
}