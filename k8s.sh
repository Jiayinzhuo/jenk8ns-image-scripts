. .env

echo "Get s3 bucket..."
## creating cluster state storage
buckets="$(aws s3api list-buckets | jq -r '.Buckets')"
found_bucket=false
for name in $( echo ${buckets} | jq -c '.[]'); do
        bucket_name=$(echo ${name} | jq -r '.Name')
        if [ ${bucket_name} == ${BUCKET_NAME} ]; then
		found_bucket=true
	fi
done

if [ ${found_bucket} == false ]; then
	echo "Create s3 bucket..."
	export BUCKET_NAME=k8s-$(date +%s)
	echo $BUCKET_NAME
	aws s3api create-bucket --bucket $BUCKET_NAME --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION
	export KOPS_STATE_STORE=s3://$BUCKET_NAME
else
	echo "Using existing s3 bucket..."
fi

echo "Creating cluster..."
# creating a cluster
kops create cluster --name $NAME --master-count 1 --master-size t2.micro --node-count 4 --node-size t2.micro --zones $ZONE --master-zones $ZONE --ssh-public-key kube-key.pub --yes
kops create cluster --dns-zone thegaijin.xyz --zones us-east-1a --master-size t2.micro --node-size t2.micro --name cluster.thegaijin.xyz --yes
while true; do
  kops validate cluster --name $NAME | grep 'is ready' &> /dev/null
  if [ $? == 0 ]; then
     break
  fi
    sleep 30
done

kops get cluster
kubectl cluster-info


#kops validate cluster
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
cd /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins config
sudo chmod 750 config