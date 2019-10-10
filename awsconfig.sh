aws configure           # Use your new access and secret key here
aws iam list-users      # you should see a list of all your IAM users here

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
