
# the Lambda's body is being uploaded via a Zip file
# this block creates a zip file from the contents of files/src
data "archive_file" "lambda1zip" {
  type        = "zip"
  source_dir  = "${path.root}/files/src/"
  output_path = "${path.root}/files/lambda1.zip"
}

# create the Lambda, using the zip file as the source file
resource "aws_lambda_function" "sayhello" {
  function_name = "sayhello"
  filename      = data.archive_file.lambda1zip.output_path
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  memory_size   = 256
  timeout       = 10
  role          = aws_iam_role.sayhellorole.arn
  environment {
    variables = {
      OFFSET = "1"
      DEBUG  = "False"
    }
  }
}

# ROLES
# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "sayhellorole" {
  name = "sayhello_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# POLICIES granted to the IAM role used by the Lambda function
resource "aws_iam_role_policy" "helloworld-lambda-policy" {
  name   = "sayhello_lambda_policy"
  role   = aws_iam_role.sayhellorole.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
		{
			"Effect": "Allow",
			"Action": "logs:CreateLogGroup",
			"Resource": "*"
		}    
  ]
}
EOF
}
