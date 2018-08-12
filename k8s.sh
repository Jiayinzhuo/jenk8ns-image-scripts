. /home/ubuntu/.env

echo "Get s3 bucket..."
# Check available buckets
buckets="$(aws s3api list-buckets | jq -r '.Buckets')"
found_bucket=false

# check if bucket already exists
for name in $( echo ${buckets} | jq -c '.[]'); do
	bucket_names=$(echo ${name} | jq -r '.Name')
	the_bucket=$(echo ${bucket_names} | grep ${BUCKET_NAME})
	if [[ ${the_bucket} == ${BUCKET_NAME} ]]; then
	found_bucket=true
	break
	fi
done

if [ ${found_bucket} == false ]; then
	echo "Create s3 bucket..."
	export BUCKET_NAME=k8s-$(date +%s)
	echo $BUCKET_NAME
	aws s3api create-bucket --bucket $BUCKET_NAME
	export KOPS_STATE_STORE=s3://$BUCKET_NAME
else
	echo "Using existing s3 bucket..."
fi

# delete key-pair to avoid name conflicts
# aws ec2 delete-key-pair --key-name /home/ubuntu/${KEY_NAME}
# echo "Nasiiimmmmwwwweeeeeennnnnnyyyyyyyyaaaaaaaa"
# ls -la
# echo "saywhat"
# ls -la /home/ubuntu

# create a new pem file
# aws ec2 create-key-pair --key-name /home/ubuntu/${KEY_NAME} | jq -r '.KeyMaterial' > /home/ubuntu/k8s-key.pem
# cat /home/ubuntu/k8s-key.pem
# echo "Lion King"
# ls -la /home/ubuntu/k8s-key.pem

chmod 400 /home/ubuntu/cp3-ami-us-east-1-key-pair.pem
echo "King of the jungle"
ls -la /home/ubuntu/cp3-ami-us-east-1-key-pair.pem

# create a public key
ssh-keygen -y -f /home/ubuntu/cp3-ami-us-east-1-key-pair.pem > /home/ubuntu/.ssh/id_rsa.pub
ls -la /home/ubuntu/.ssh/id_rsa.pub
cat /home/ubuntu/.ssh/id_rsa.pub

echo "Creating cluster..."
# creating a cluster
current=$(eval whoami)
echo $current
kops create cluster --dns-zone thegaijin.xyz --zones us-east-1a --master-size t2.micro --node-size t2.micro --name $CLUSTER_NAME --ssh-public-key /home/ubuntu/.ssh/id_rsa.pub --yes

# echo "Kubectil certificate issue"
# kops export kubecfg --name $CLUSTER_NAME
# echo "Do the .kube ting"
# mkdir -p /.kube
# sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
# sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config

echo "************************ validate cluster **************************"
while true; do
  kops validate cluster --name $CLUSTER_NAME | grep 'is ready' &> /dev/null
  if [ $? == 0 ]; then
     break
  fi
    sleep 30
done

echo "<<<<<<<<<<<<< get the cluster >>>>>>>>>>>>>"
kops get cluster
kubectl cluster-info


echo "Jenkins shit"
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
cd /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins config
sudo chmod 750 config