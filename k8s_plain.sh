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
	echo "Create the bucket..."
	export BUCKET_NAME=devopsjonathanzhuo
	aws s3api create-bucket --bucket devopsjonathanzhuo
	export KOPS_STATE_STORE=s3://devopsjonathanzhuo
fi

echo "Generate public key from pem file"
chmod 400 /home/ubuntu/jenk8ns-key-pair.pem
ssh-keygen -y -f /home/ubuntu/jenk8ns-key-pair.pem > /home/ubuntu/.ssh/id_rsa.pub

echo "Creating cluster..."
kops create cluster --dns-zone jonathanzhuo.com --zones us-east-1a --master-size t2.medium --node-size t2.medium --name devopscluster.jonathanzhuo.com --state s3://devopsjonathanzhuo --ssh-public-key /home/ubuntu/.ssh/id_rsa.pub --yes
echo "Updating cluster..."
kops update cluster devopscluster.jonathanzhuo.com --yes
echo "************************ validate cluster **************************"
while true; do
  kops validate cluster --name devopscluster.jonathanzhuo.com | grep 'is ready' &> /dev/null
  if [ $? == 0 ]; then
    break
  fi
    sleep 90
done

echo "<<<<<<<<<<<<< get the cluster >>>>>>>>>>>>>"
kops get cluster
kubectl cluster-info

echo "Add Dashboard and User"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl describe secret kubernetes-dashboard --namespace=kube-system

echo "Add ingress"
kubectl create namespace ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
helm init --upgrade
echo "helm install nginx-ingress"
helm install stable/nginx-ingress --name my-nginx --set rbac.create=true

echo "Add jenkins user to docker group"
sudo usermod -a -G docker jenkins
sudo service jenkins restart

echo "Give Jenkins rights to run kubernetes"
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
cd /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins config
sudo chmod 750 config
