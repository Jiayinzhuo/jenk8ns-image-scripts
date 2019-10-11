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
	export BUCKET_NAME=$BUCKET_NAME
	aws s3api create-bucket --bucket $BUCKET_NAME
	export KOPS_STATE_STORE=s3://$BUCKET_NAME
fi

echo "Generate public key from pem file"
chmod 400 /home/ubuntu/jenk8ns-key-pair.pem
ssh-keygen -y -f /home/ubuntu/jenk8ns-key-pair.pem > /home/ubuntu/.ssh/id_rsa.pub

echo "Creating cluster..."
kops create cluster --dns-zone jonathanzhuo.com --zones us-east-1a --master-size t2.medium --node-size t2.medium --name $CLUSTER_NAME --state $KOPS_STATE_STORE --ssh-public-key /home/ubuntu/.ssh/id_rsa.pub --yes
echo "Updating cluster..."
kops update cluster $CLUSTER_NAME --yes
echo "************************ validate cluster **************************"
while true; do
  kops validate cluster --name $CLUSTER_NAME | grep 'is ready' &> /dev/null
  if [ $? == 0 ]; then
    break
  fi
    sleep 90
done

echo "<<<<<<<<<<<<< get the cluster >>>>>>>>>>>>>"
kops get cluster
kubectl cluster-info
#kubectl apply namespace ingress

echo "Add Dashboard and User"
#kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.4.0.yaml
#kubectl create secret generic kubernetes-dashboard-certs --from-file=$HOME/certs -n kubernetes-dashboard
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
#kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/alternative.yaml

#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/Jiayinzhuo/jenk8ns-image-scripts/master/dashboard-adminuser.yaml
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

echo "Add ingress"
kubectl create namespace ingress-nginx
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
helm init --upgrade
echo "helm install nginx-ingress"
helm install stable/nginx-ingress --name my-nginx --set rbac.create=true
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/aws/service-l4.yaml
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/aws/patch-configmap-l4.yaml

echo "Add jenkins user to docker group"
sudo usermod -a -G docker jenkins
sudo service jenkins restart

echo "Give Jenkins rights to run kubernetes"
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/
cd /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins config
sudo chmod 750 config

echo "<<<<<<<<<<<<< get the cluster again >>>>>>>>>>>>>"
#kubectl get nodes
#kubectl get services
echo "kubectl get deployments --all-namespaces"
kubectl get deployments --all-namespaces
#kubectl -n kube-system get po
echo "kubectl get serviceAccounts"
kubectl get serviceAccounts
echo "kubectl config view --minify | grep namespace:"
kubectl config view --minify | grep namespace:
echo "kubectl config view"
kubectl config view
