Creating a simple Lambda-based API
==================================

This code fragment shows how to create a simple API using API Gateway and a Lambda function.

The API gateway is created by _apigateway.tf_ and _helloworld.yaml_. The yaml is an OpenAPI 3.0 template file which defines the API. The only parts of this which are AWS specific are the sections starting "x-amazon", which define what Lambda function is called by the API, how it is called, whether any authorization scheme is in place (no), and whether any API key is required (yes). 

The terraform module creates the api gateway and all associated cloud infrastructure. It also creates an API key, the value of which can be read from the Terraform state file after successful execution.  The module also prints out the API's URL for testing purposes. 

The Lambda function is created by _lambda.tf_. The lambda function's code payload is stored in files/src, and is zipped by Terraform before being uploaded to AWS and used to create the Lambda. The code also includes an example of how to grant the lambda extra permissions to access other AWS resources.

_provider.tf_ informs terraform that we want to execute the code against AWS. 

_vars.tf_ contains variables that reference your account. These are automatically populated at run-time by Terraform using the AWS configuration that you previously set up. This ensures that your key and secret are not stored in public. 

To use this code in a new project, copy everything to a new folder. To use this code in an existing terraform project, copy everything except provider.tf and vars.tf to a new folder. 