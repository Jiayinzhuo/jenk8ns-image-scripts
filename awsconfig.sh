aws configure           # Use your new access and secret key here
aws iam list-users      # you should see a list of all your IAM users here

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)




#Note
#AWS_ACCESS_KEY_ID
#Specifies an AWS access key associated with an IAM user or role.
#If defined, this environment variable overrides the value for the profile setting #aws_access_key_id. You can't specify the access key ID by using a command line option.

#AWS_SECRET_ACCESS_KEY
#Specifies the secret key associated with the access key. This is essentially the #"password" for the access key.
#If defined, this environment variable overrides the value for the profile setting #aws_secret_access_key. You can't specify the access key ID as a command line option.