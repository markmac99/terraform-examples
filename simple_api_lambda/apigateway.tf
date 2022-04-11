# variable used in the api definition YAML file
variable "lambda_identity_timeout" { default = 1000 }

# create a REST API gateway
resource "aws_api_gateway_rest_api" "sayhello-api-gateway" {
  name           = "SayHelloAPI"
  description    = "Demo API to Say Hello"
  api_key_source = "HEADER"
  body           = "${data.template_file.helloworld.rendered}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# template file containing the OPENAPI3 definition of the API
data "template_file" "helloworld" {
  template = "${file("helloworld.yaml")}"
  vars = {
    get_lambda_arn          = "${aws_lambda_function.sayhello.arn}"
    aws_region              = var.region
    lambda_identity_timeout = var.lambda_identity_timeout
  }

}

# create a stage (eg dev/ test / prod)
resource "aws_api_gateway_stage" "sayhellostage" {
  deployment_id = aws_api_gateway_deployment.sayhellodeployment.id
  rest_api_id   = aws_api_gateway_rest_api.sayhello-api-gateway.id
  stage_name    = "stage1"
}

# create a deployment of the gateway
resource "aws_api_gateway_deployment" "sayhellodeployment" {
  rest_api_id = aws_api_gateway_rest_api.sayhello-api-gateway.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.sayhello-api-gateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# print out the URL of the API 
output "url" {
  value = "${aws_api_gateway_deployment.sayhellodeployment.invoke_url}/"
}

# create an API key to improve security
resource "aws_api_gateway_api_key" "sayhello" {
  name = "sayhellokey"
}

# link the key to the usage plan
resource "aws_api_gateway_usage_plan_key" "devUsageKey" {
  key_id        = aws_api_gateway_api_key.sayhello.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.DevUsagePlan.id
}

# usage plan attached to the gateway
resource "aws_api_gateway_usage_plan" "DevUsagePlan" {
  name         = "dev-usage-plan"
  description  = "dev usage plan for say hello"
  product_code = "sayhello"

  api_stages {
    api_id = aws_api_gateway_rest_api.sayhello-api-gateway.id
    stage  = aws_api_gateway_stage.sayhellostage.stage_name
  }

  quota_settings {
    limit  = 1000
    offset = 0
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 100
  }
}

# grants the API gateway permission to invoke the Lambda 
resource "aws_lambda_permission" "api-gateway-invoke-lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sayhello.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the specified API Gateway.
  source_arn = "${aws_api_gateway_rest_api.sayhello-api-gateway.execution_arn}/*/*"
}
