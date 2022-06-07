# add a profile section to the ~/.aws/credentials file
# [folder1role]
# role_arn = arn:aws:iam::<accountid>:role/folder1role
# source_profile = default
#
aws s3 ls s3://mjmm-test-perms/folder1/ --profile folder1role
aws s3 ls s3://mjmm-test-perms/folder2/ --profile folder1role