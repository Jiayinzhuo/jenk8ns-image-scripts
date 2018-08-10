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

echo "Creating cluster..."
# creating a cluster
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