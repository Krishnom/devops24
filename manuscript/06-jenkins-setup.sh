cd k8s-specs

git pull

JENKINS_ADDR="jenkins.$LB_IP.nip.io"

echo $JENKINS_ADDR

# Only if minishift
oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'

kubectl create namespace jenkins

helm install jenkins stable/jenkins \
    --namespace jenkins \
    --values helm/jenkins-values2.yml \
    --set master.hostName=$JENKINS_ADDR

kubectl --namespace jenkins \
    rollout status deployment jenkins

# Only if minishift
oc -n jenkins create route edge --service jenkins --insecure-policy Allow --hostname $JENKINS_ADDR

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

kubectl --namespace jenkins get pods

open "http://$JENKINS_ADDR/job/my-k8s-job/configure"

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

kubectl --namespace jenkins get pods

kubectl --namespace jenkins get pods

open "http://$JENKINS_ADDR/job/my-k8s-job/configure"

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

cat ../go-demo-3/k8s/build-ns.yml

kubectl apply \
    -f ../go-demo-3/k8s/build-ns.yml \
    --record

cat ../go-demo-3/k8s/prod-ns.yml

kubectl apply \
    -f ../go-demo-3/k8s/prod-ns.yml \
    --record

cat ../go-demo-3/k8s/jenkins.yml

kubectl apply \
    -f ../go-demo-3/k8s/jenkins.yml \
    --record

open "http://$JENKINS_ADDR/configure"

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

kubectl --namespace go-demo-3-build \
    get pods

# Only if using Vagrant for building containers
cd cd/docker-build

# Only if using Vagrant for building containers
cat Vagrantfile

# Only if using Vagrant for building containers
vagrant up

# Only if using Vagrant for building containers
open "http://$JENKINS_ADDR/computer/new"

# Only if using Vagrant for building containers
cat .vagrant/machines/docker-build/virtualbox/private_key

# Only if using Vagrant for building containers
cd ../../

# Only if using EC2 for building containers
aws ec2 create-security-group \
    --description "For building Docker images" \
    --group-name docker \
    | tee cluster/sg.json

# Only if using EC2 for building containers
SG_ID=$(cat cluster/sg.json \
    | jq -r ".GroupId")

# Only if using EC2 for building containers
echo $SG_ID

# Only if using EC2 for building containers
echo "export SG_ID=$SG_ID" \
    | tee -a cluster/docker-ec2

# Only if using EC2 for building containers
aws ec2 \
    authorize-security-group-ingress \
    --group-name docker \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Only if using EC2 for building containers
cat jenkins/docker-ami.json

# Only if using EC2 for building containers
packer build -machine-readable \
    jenkins/docker-ami.json \
    | tee cluster/docker-ami.log

# Only if using EC2 for building containers
AMI_ID=$(grep 'artifact,0,id' \
    cluster/docker-ami.log \
    | cut -d: -f2)

# Only if using EC2 for building containers
echo $AMI_ID

# Only if using EC2 for building containers
echo "export AMI_ID=$AMI_ID" \
    | tee -a cluster/docker-ec2

# Only if using EC2 for building containers
open "http://$JENKINS_ADDR/configure"

# Only if using EC2 for building containers
echo $AWS_ACCESS_KEY_ID

# Only if using EC2 for building containers
echo $AWS_SECRET_ACCESS_KEY

# Only if using EC2 for building containers
aws ec2 create-key-pair \
    --key-name devops24 \
    | jq -r '.KeyMaterial' \
    >cluster/devops24.pem

# Only if using EC2 for building containers
chmod 400 cluster/devops24.pem

# Only if using EC2 for building containers
cat cluster/devops24.pem

# Only if using EC2 for building containers
echo $AMI_ID

# Only if using GCE for building containers
gcloud auth login

# Only if using GCE for building containers
gcloud iam service-accounts \
    create jenkins

# Only if using GCE for building containers
export G_PROJECT=$(gcloud info \
    --format='value(config.project)')

# Only if using GCE for building containers
echo $G_PROJECT

# Only if using GCE for building containers
export SA_EMAIL=$(gcloud iam \
    service-accounts list \
    --filter="name:jenkins" \
    --format='value(email)')

# Only if using GCE for building containers
echo $SA_EMAIL

# Only if using GCE for building containers
gcloud projects add-iam-policy-binding \
    --member serviceAccount:$SA_EMAIL \
    --role roles/compute.admin \
    $G_PROJECT

# Only if using GCE for building containers
gcloud projects add-iam-policy-binding \
    --member serviceAccount:$SA_EMAIL \
    --role roles/iam.serviceAccountUser \
    $G_PROJECT

# Only if using GCE for building containers
gcloud iam service-accounts \
    keys create \
    --iam-account $SA_EMAIL \
    cluster/gce-jenkins.json

# Only if using GCE for building containers
cat jenkins/docker-gce.json

# Only if using GCE for building containers
packer build -machine-readable \
    --force \
    -var "project_id=$G_PROJECT" \
    jenkins/docker-gce.json \
    | tee cluster/docker-gce.log

# Only if using GCE for building containers
open "http://$JENKINS_ADDR/configure"

# Only if using GCE for building containers
echo $JENKINS_PASS

# Only if using GCE for building containers
echo $G_PROJECT

open "http://$JENKINS_ADDR/job/my-k8s-job/configure"

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

mkdir -p cluster/jenkins/secrets

kubectl --namespace jenkins \
    describe deployment jenkins

kubectl --namespace jenkins \
    get pods \
    --selector app.kubernetes.io/component=jenkins-master

JENKINS_POD=$(kubectl --namespace jenkins \
    get pods \
    --selector app.kubernetes.io/component=jenkins-master \
    --output jsonpath='{.items[0].metadata.name}')

echo $JENKINS_POD

kubectl --namespace jenkins cp \
    $JENKINS_POD:var/jenkins_home/credentials.xml \
    cluster/jenkins/credentials.xml

kubectl --namespace jenkins cp \
    $JENKINS_POD:var/jenkins_home/secrets/hudson.util.Secret \
    cluster/jenkins/secrets/hudson.util.Secret

kubectl --namespace jenkins cp \
    $JENKINS_POD:var/jenkins_home/secrets/master.key \
    cluster/jenkins/secrets/master.key

# Only if using GCE for building containers
kubectl -n jenkins cp $JENKINS_POD:var/jenkins_home/gauth/ cluster/jenkins/secrets

# Only if using GCE for building containers
G_AUTH_FILE=$(ls cluster/jenkins/secrets/key*json | xargs -n 1 basename)

# Only if using GCE for building containers
echo $G_AUTH_FILE

helm --namespace jenkins delete jenkins

ls -1 helm/jenkins

cat helm/jenkins2/requirements.yaml

helm inspect readme stable/jenkins

cat helm/jenkins2/values.yaml

cat helm/jenkins2/templates/config.tpl

helm dependency update helm/jenkins

ls -1 helm/jenkins/charts

kubectl --namespace jenkins \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml

kubectl --namespace jenkins \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets

helm install jenkins helm/jenkins \
    --namespace jenkins \
    --values helm/jenkins2/values.yaml \
    --set jenkins.master.hostName=$JENKINS_ADDR \
    --set jenkins.master.DockerVM=$DOCKER_VM \
    --set jenkins.master.DockerAMI=$AMI_ID \
    --set jenkins.master.GProject=$G_PROJECT \
    --set jenkins.master.GAuthFile=$G_AUTH_FILE

kubectl --namespace jenkins \
    rollout status deployment jenkins

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

open "http://$JENKINS_ADDR/configure"

# Only if using EC2 for building containers
cat cluster/devops24.pem

# Only if using VirtualBox for building containers
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/docker-build/update"

# Only if using EC2 for building containers
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/aws/update"

# Only if using GCE for building containers
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/$G_PROJECT/update"

open "http://$JENKINS_ADDR/computer"

open "http://$JENKINS_ADDR/newJob"

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

helm delete $(helm ls -q) --purge

kubectl delete ns \
    go-demo-3 go-demo-3-build jenkins

# Only if using VirtualBox for building containers
cd cd/docker-build

# Only if using VirtualBox for building containers
vagrant suspend

# Only if using VirtualBox for building containers
cd ../../
