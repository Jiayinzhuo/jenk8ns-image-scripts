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
kops create cluster --dns-zone jonathanzhuo.com --node-count 2 --zones us-east-1a,us-east-1b,us-east-1c --master-size t2.medium --node-size t2.medium --master-zones us-east-1a --name devopscluster.jonathanzhuo.com --state s3://devopsjonathanzhuo --ssh-public-key /home/ubuntu/.ssh/id_rsa.pub --yes
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
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/Jiayinzhuo/jenk8ns-image-scripts/master/dashboard-adminuser.yaml
kubectl -n default describe secret $(kubectl -n default get secret | grep admin-user | awk '{print $1}')

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

echo "kubectl config view"
kubectl config view

####Results#####
NAME				CLOUD	ZONES
devopscluster.jonathanzhuo.com	aws	us-east-1a
Kubernetes master is running at https://api.devopscluster.jonathanzhuo.com
KubeDNS is running at https://api.devopscluster.jonathanzhuo.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
Add Dashboard and User
secret/kubernetes-dashboard-certs created
serviceaccount/kubernetes-dashboard created
role.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
deployment.apps/kubernetes-dashboard created
service/kubernetes-dashboard created
Name:         kubernetes-dashboard-certs
Namespace:    kube-system
Labels:       k8s-app=kubernetes-dashboard
Annotations:  
Type:         Opaque

Data
====

Name:         kubernetes-dashboard-token-cdzsb
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: kubernetes-dashboard
              kubernetes.io/service-account.uid: 96063aad-062a-11ea-afa4-120e6f40663d

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1042 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZC10b2tlbi1jZHpzYiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6Ijk2MDYzYWFkLTA2MmEtMTFlYS1hZmE0LTEyMGU2ZjQwNjYzZCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTprdWJlcm5ldGVzLWRhc2hib2FyZCJ9.dceH1iLNiC0D7WyfNdThC2hDUU68vvSHl8mPW9-iROOG52ODAFz62mtKGdjUv2AGKUbxPT4nn5NcO_mB9oXmcCFN9HPfEZLLkibjqhEGFBMPnsm_A2j5ewnNHNNfTjMD-IC5-ZeG80jY4MCVIJb53X8dmxHjNB3-Nv38kt9KeBZOxLm3MZ_JF_6meryqdNrFjOCXi6g30iSod_b4DWn7Zm7BDeNUXDcXIsoS7osnldXOil67lbU422DukxTThMw-zlowrZQCUAq3VG-FY9x_wbN_dLGdo9PkFweTiHnK4tTl0i5LXg9gUuB6uAr7wVgDbkEX-sm-zpsqjZm7MMg7Jg

Add ingress
namespace/ingress-nginx created
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
namespace/ingress-nginx configured
configmap/nginx-configuration created
configmap/tcp-services created
configmap/udp-services created
serviceaccount/nginx-ingress-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-role created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-role-nisa-binding created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-clusterrole-nisa-binding created
deployment.apps/nginx-ingress-controller created
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  7164  100  7164    0     0  67024      0 --:--:-- --:--:-- --:--:-- 67584
Helm v2.16.1 is already latest
Run 'helm init' to configure helm.
$HELM_HOME has been configured at /home/ubuntu/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
helm install nginx-ingress
Error: could not find a ready tiller pod
Add jenkins user to docker group
Give Jenkins rights to run kubernetes
kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://api.devopscluster.jonathanzhuo.com
  name: devopscluster.jonathanzhuo.com
contexts:
- context:
    cluster: devopscluster.jonathanzhuo.com
    user: devopscluster.jonathanzhuo.com
  name: devopscluster.jonathanzhuo.com
current-context: devopscluster.jonathanzhuo.com
kind: Config
preferences: {}
users:
- name: devopscluster.jonathanzhuo.com
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
    password: mWoevr9oFKMXtjPdfMQ4eymcmKh2g5Lm
    username: admin
- name: devopscluster.jonathanzhuo.com-basic-auth
  user:
    password: mWoevr9oFKMXtjPdfMQ4eymcmKh2g5Lm
    username: admin
