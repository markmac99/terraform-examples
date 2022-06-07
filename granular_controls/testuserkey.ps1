# add a profile sections to the ~/.aws/credentials file
# [folder1role]
# role_arn = arn:aws:iam::<accountid>:role/folder1role
# source_profile = default
#
write-output "checking folder1 with folder1role"
aws s3 ls s3://mjmm-test-perms/folder1/ --profile folder1role
write-output "checking folder2 with folder1role"
aws s3 ls s3://mjmm-test-perms/folder2/ --profile folder1role

write-output "checking folder1 with folder2role"
aws s3 ls s3://mjmm-test-perms/folder1/ --profile folder2role
write-output "checking folder2 with folder2role"
aws s3 ls s3://mjmm-test-perms/folder2/ --profile folder2role