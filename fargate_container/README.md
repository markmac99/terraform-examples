# SUMMARY
This example creates a simple Flask webapp in a container running in ECS on Fargate, without requiring Docker to be installed on the developer's local machine. 

The first part of the project creates a docker container using CodeBuild, then pushes it into ECR. 
The second part creates an ECS cluster on Fargate and runs the container. 
The third part shows how to redeploy the container to other environments. 
No attempt has been made to add autoscaling or other advanced features.  If you want those, you'll need to read the Terraform documentation! 

All the assets including a CodeBuild project are created with Terraform, however you must login to the AWS console to trigger the CodeBuild project that builds the container and pushes it into ECR. This is deliberate as you do not want to accidentally overwrite a running container. 

# Step 1: Creating the Docker Image
__mycontainer.tf__ zips the contents of step1/ (Dockerfile, application code app.py and CodeBuild build script), uploads the zip file to an S3 bucket, then creates a CodeBuild project that can build the image and push it into ECR.  

To execute the CodeBuild project you must login to the AWS console. The CodeBuild project actions are specified in __step1/buildspec.yml__. The script creates the container, tags it and pushes it to an ECR repository. It also saves a gzipped tarball of the container image. This allows you to build the image in a lower environment where you may have internet access, but then deploy it to a more secure environment.  

# Step 2: Running the Image
ECS normally requires internet access to pull images from ECR. In this example I've provided an Internet Gateway, however you can also use a NAT Gateway, AWS PrivateLink or other route to the ECR repository.

All code relating to building the ECS cluster is in __ecscluster.tf.step2__.  Initially the file has been named so that Terraform does not execute it too soon. This is necessary because the container image is not in ECR until you manually run CodeBuild. Once you've completed step 1, you can rename this file and rerun Terraform, which will now build the ECS cluster and load a task to execute your container. 

The task itself is defined in __step2/webapp.json__, and in this case defines a simple, nonscaling container. You can of course tailor this to run your own app. 

The service was specified as having a public IP address which can be obtained from the AWS Console by going to ECS, selecting the Cluster, then Tasks, then the task definition. If there's a way to export this from Terraform it'd be great. 

If you don't want a public IP you can disable this by changing __assign_public_ip__ to false in __ecscluster.tf__. How you then access the service is left as an exercise for the reader. 

# Step 3: Loading the Image in Other Environments
Step 2 created a tarball of the container image which can be downloaded from S3. The terraform in step 3 starts by uploading the tarball to an S3 bucket, then creating a codebuild script that loads it into Docker and pushes it to a new ECR repository.  The code for this is in __prodcontainer.tf.step3__ which you can rename or use as required. 

You can then tweak the step 2 json to reference the new image, and run the step 2 terraform in your new environment to create an ECS cluster loading the image. 
