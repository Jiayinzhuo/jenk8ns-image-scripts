# jenk8ns-image-scripts

### Creating the Jenkins AMI on AWS with Packer and Ansible

If you have no experience with Packer and Ansible, I recommend you read my [article](https://medium.com/@Thegaijin/configuration-and-change-management-with-packer-and-ansible-f0a16677e28f) where I detailed how to provision and configure an image with them.
In the packer template json file we set the type of builder to be `amazon-ebs`, and the region to be `us-east-1`.
The `access_key` and `secret_key` are set to be picked up from the aws cli tools configurations.
The source AMI image ID, `source_ami` is also set here, in this case I used an ubuntu-16.04 image, as well the the instance type to use. I'd suggest you use the same image however if you choose to use a different one, make sure it has all the packages you need to setup the Jenkins server. Every image comes with different packages installed. You might need to install some other packages that I didn't not have to install in this setup.

In the Provisioners we import the /.env file which has the cluster name, S3 bucket name and the zone we would like to create the cluster in. The pem file to be used to create a public key and the `k8s.sh` script file.

Change the pem file name to your pem file's name.

The last provisioner is the ansible playbook which has the instructions on how the imagine should be configured.

In the ansible playbook we have roles, each of these roles is a set of configuration steps.

### setup role

Here we install the awscli, java, nginx, python and jq.

#### webserver

Here we setup a nginx to reverse proxy from port 8080 to port 80 and set a server name: `jenkins.jonathanzhuo.com`

#### jenkins

Here we install `jenkins` and start `jenkins`

#### aws (awscli)

Here we setup the `awscli` such that we can run aws commands in the Jenkins server instance. /home/ubuntu/.aws/config, /home/ubuntu/.aws/credentials

#### k8s (kubectl, kops)

Install `kubectl` the kubernetes commandline tool and `kops` a commandline tool for getting a production grade cluster up and running.

#### docker (docker, docker-compose)

Install `docker` and `docker-compose` so we can run docker commands in the server.

In the playbook we also set the AWS credentials in the environment so that they are available in the image.

To create the image make sure you have set the aws credentials in the awscli configurations then run

    packer build jenk8ns-template.json

Once the image has been created, head over to AWS images and under my AMI, you should see the newly created image with the image name you set in the packer template.

Create an instance with that image, once it's being created, copy the instance external IP and head over to `Route53` to create an `A record` with the domain name you set when configuring nginx, in my case, `jenkins.jonathanzhuo.com`. An assumption has been made that you already have an existing domain.

ssh into the image and run the k8s.sh script. This will create the cluster.

    . k8s.sh

to delete the cluster, run

    kops delete cluster <name of cluster> --yes
    kops delete cluster --name="devopscluster.jonathanzhuo.com" --state="s3://devopsjonathanzhuo" --yes

You can also make changes to the k8s.sh file as well as the .env file as per your preferences. They are both there in the `/home/ubuntu` directory.

#### .env
awsconfig.sh
jenk8ns-key-pair.pem
jenk8ns-playbook.yml
jenk8ns-template.json
k8s.sh

roles/aws/tasks/main.yml
roles/docker/tasks/main.yml
roles/jenkins/tasks/main.yml
roles/k8s/tasks/main.yml
roles/setup/tasks/main.yml
roles/service/tasks/main.yml
roles/start/tasks/main.yml
roles/webserver/tasks/main.yml
