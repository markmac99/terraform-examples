$id=(aws codebuild start-build --project-name testwebapp --profile default --region eu-west-2 | convertfrom-Json).build.id
write-output "taskid is $id"
echo "to check status do (aws codebuild --profile default --region eu-west-2 batch-get-builds --ids $id | convertfrom-json).builds.buildStatus"

