cd k8s-specs

git pull

# Only if MacOS
brew install kubernetes-helm

# Only if Windows
choco install kubernetes-helm

# Only if Linux
open https://github.com/kubernetes/helm/releases

# Only if Linux
# Download `tar.gz` file, unpack it, and move the binary to `/usr/local/bin/`.

cat helm/tiller-rbac.yml

kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config

helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy

kubectl -n kube-system get pods

helm repo update

helm search

helm search jenkins

# Only if minishift
oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins

# Only if minikube
helm upgrade jenkins stable/jenkins \
    --set Master.ServiceType=NodePort

# Only if minishift
oc -n jenkins create route edge \
    --service jenkins \
    --insecure-policy Allow

kubectl -n jenkins \
    rollout status deploy jenkins

ADDR=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080

# Only if minikube
ADDR=$(minikube ip):$(kubectl -n jenkins get svc jenkins -o jsonpath="{.spec.ports[0].nodePort}")

# Only if GKE
ADDR=$(kubectl -n jenkins get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

# Only if minishift
ADDR=$(oc -n jenkins get route jenkins -o jsonpath="{.status.ingress[0].host}")

echo $ADDR
```

The format of the output will differ from one Kubernetes flavor to another. In case of AWS with kops, it should be similar to the one that follows.

```
...us-east-2.elb.amazonaws.com
```

Now we can finally open Jenkins. We won't do much with it. Our goal, for now, is only to confirm that it is up-and-running.

```bash
open "http://$ADDR"
```

W> Remember that if you are a **Windows user**, you'll have to replace `open` with `echo`, copy the output, and paste it into a new tab of your browser of choice.

You should be presented with the login screen. There is no setup wizard indicating that this Helm chart already configured Jenkins with some sensible default values. That means that, among other things, the Chart created a user with a password during the automated setup. We need to discover it.

Fortunately, we already saw from the `helm install` output that we should retrieve the password by retrieving the `jenkins-admin-password` entry from the `jenkins` secret. If you need to refresh your memory, please scroll back to the output, or ignore it all together and execute the command that follows.

```bash
kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo
```

The output should be a random set of characters similar to the one that follows.

```
shP7Fcsb9g
```

Please copy the output and return to Jenkins` login screen in your browser. Type *admin* into the *User* field, paste the copied output into the *Password* field, and click the *log in* button.

Mission accomplished. Jenkins is up-and-running without us spending any time writing YAML file with all the resources. It was set up automatically with the administrative user and probably quite a few other goodies. We'll get to them later. For now, we'll "play" with a few other `helm` commands that might come in handy.

If you are ever unsure about the details behind one of the Helm Charts, you can execute `helm inspect`.

```bash
helm inspect stable/jenkins
```

The output of the `inspect` command is too big to be presented in a book. It contains all the information you might need before installing an application (in this case Jenkins).

If you prefer to go through the available Charts visually, you might want to visit [Kubeapps](https://kubeapps.com/) project hosted by [bitnami](https://bitnami.com/). Click on the *Explore Apps* button and you'll be sent to the hub with the list of all the official Charts. If you search for Jenkins, you'll end up on the [page with the Chart's details](https://hub.kubeapps.com/charts/stable/jenkins). You'll notice that the info in that page is the same as the output of the `inspect` command.

We won't go back to [Kubeapps](https://kubeapps.com/) since I prefer command line over UIs. A strong grip on the command line helps a lot when it comes to automation, which happens to be the goal of this book.

With time, the number of the Charts running in your cluster with increase and you might be in need to list them. You can do that with the `ls` command.

```bash
helm ls
```

The output is as follows.

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 1        Thu May ... DEPLOYED jenkins-0.16.1 jenkins
```

There is not much to look at right now since we have only one Chart. Just remember that the command exist. It'll come in handy later on.

If you need to see the details behind one of the installed Charts, please use the `status` command.

```bash
helm status jenkins
```

The output should be very similar to the one you saw when we installed the Chart. The only difference is that, this time, all the Pods are running.

Tiller obviously stores the information about the installed Charts somewhere. Unlike most other applications that tend to store their state on disk, or replicate data across multiple instances, tiller uses Kubernetes ConfgMaps to preserve its state.

Let's take a look at the ConfigMaps in the `kube-system` Namespace where tiller is running.

```bash
kubectl -n kube-system get cm
```

The output, limited to the relevant parts, is as follows.

```
NAME       DATA AGE
...
jenkins.v1 1    25m
...
```

We can see that there is a config named `jenkins.v1`. We did not explore revisions just yet. For now, just assume that each new installation of a Chart is version 1.

Let's take a look at the contents of the ConfigMap.

```bash
kubectl -n kube-system \
    describe cm jenkins.v1
```

The output is as follows.

```
Name:        jenkins.v1
Namespace:   kube-system
Labels:      MODIFIED_AT=1527424681
             NAME=jenkins
             OWNER=TILLER
             STATUS=DEPLOYED
             VERSION=1
Annotations: <none>

Data
====
release:
----
[ENCRYPTED RELEASE INFO]
Events:  <none>
```

I replaced the content of the release Data with `[ENCRYPTED RELEASE INFO]` since it is too big to be presented in the book. The release contains all the info tiller used to create the first `jenkins` release. It is encrypted as a security precaution.

We're finished exploring our Jenkins installation so our next step is to remove it.

```bash
helm delete jenkins
```

The output shows that the `release "jenkins"` was `deleted`.

Since this is the first time we deleted a Helm Chart, we might just as well confirm that all the resources were indeed removed.

```bash
kubectl -n jenkins get all
```

The output is as follows.

```
NAME           READY STATUS      RESTARTS AGE
po/jenkins-... 0/1   Terminating 0        5m
```

Everything is gone except the Pod that is still `terminating`. Soon it will disappear as well, and there will be no trace of Jenkins anywhere in the cluster. At least, that's what we're hoping for.

Let's check the status of the `jenkins` Chart.

```bash
helm status jenkins
```

The relevant parts of the output are as follows.

```
LAST DEPLOYED: Thu May 24 11:46:38 2018
NAMESPACE: jenkins
STATUS: DELETED

...
```

If you expected an empty output or an error stating that `jenkins` does not exist, you were wrong. The Chart is still in the system, only this time it's status is `DELETED`. You'll notice that all the resources are gone though.

When we execute `helm delete [THE_NAME_OF_A_CHART]`, we are only removing the Kubernetes resources. The Chart is still in the system. We could, for example, revert the `delete` action and return to the previous state with Jenkins up-and-running again.

If you want to delete not only the Kubernetes resources created by the Chart but also the Chart itself, please add `--purge` argument.

```bash
helm delete jenkins --purge
```

The output is still the same as before. It states that the `release "jenkins"` was `deleted`.

Let's check the status now after we purged the system.

```bash
helm status jenkins
```

The output is as follows.

```
Error: getting deployed release "jenkins": release: "jenkins" not found
```

This time, everything was removed and `helm` cannot find the `jenkins` Chart any more.

## Customizing Helm Installations

We'll almost never install a Chart as we did. Even though the default values do often make a lot of sense, there is always something we need to tweak to make an application behave as we desire.

What if we do not want the Jenkins tag predefined in the Chart? What if for some reason we want to deploy Jenkins `2.112-alpine`? There must be a sensible way to change the tag of the `stable/jenkins` Chart.

Helm allows us to modify installation through variables. All we need to do is to find out which variables are available.

Besides visiting project's documentation, we can retrieve the available values through the command that follows.

```bash
helm inspect values stable/jenkins
```

The output, limited to the relevant parts, is as follows.

```
...
Master:
  Name: jenkins-master
  Image: "jenkins/jenkins"
  ImageTag: "lts"
  ...
```

We can see that within the `Master` section there is a variable `ImageTag`. The name of the variable should be, in this case, sufficiently self-explanatory. If we need more information, we can always inspect the Chart.

```bash
helm inspect stable/jenkins
```

I encourage you to read the whole output as some later moment. For now, we care only about the `ImageTag`.

The output, limited to the relevant parts, is as follows.

```
...
| Parameter         | Description      | Default |
| ----------------- | ---------------- | ------- |
...
| `Master.ImageTag` | Master image tag | `lts`   |
...
```

That did not provide much more info. Still, we do not really need more than that. We can assume that `Master.ImageTag` will allow us to replace the default value `lts` with `2.112-alpine`.

If we go through the documentation, we'll discover that one of the ways to overwrite the default values is through the `--set` argument. Let's give it a try.

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set Master.ImageTag=2.112-alpine
```

W> ## A note to minikube users
W>
W> We still need to change the `jenkins` Service type to `NodePort`. Since this is specific to minikube, I did not want to include it in the command we just executed. Instead, we'll run the same command as before. Please execute the command that follows.
W>
W> `helm upgrade jenkins stable/jenkins --set Master.ServiceType=NodePort --reuse-values`
W>
W> We still did not go through the `upgrade` process. For now, just note that we changed the Service type to `NodePort`.
W> 
W> Alternatively, you can `delete` the chart and install it again but, this time, with the `--set Master.ServiceType=NodePort` argument added to `helm install`.

W> ## A note to minishift users
W>
W> The Route we created earlier still exists, so we do not need to create it again.

The output of the `helm install` command is almost the same as when we executed it the first time, so there's probably no need to go through it again. Instead, we'll wait until `jenkins` rolls out.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

Now that the Deployment rolled out, we are almost ready to test whether the change of the variable had any effect. First we need to get the Jenkins address. We'll retrieve it in the same way as before, so there's no need to lengthy explanation.

```bash
ADDR=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080
```

W> ## A note to minikube users
W>
W> As a reminder, the command to retrieve the address from minikube is as follows.
W> 
W> `ADDR=$(minikube ip):$(kubectl -n jenkins get svc jenkins -o jsonpath="{.spec.ports[0].nodePort}")`

W> ## A note to GKE users
W>
W> As a reminder, the command to retrieve the address from GKE is as follows.
W> 
W> `ADDR=$(kubectl -n jenkins get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080`

W> ## A note to minishift users
W>
W> As a reminder, the command to retrieve the address from the OpenShift route is as follows.
W> 
W> `ADDR=$(oc -n jenkins get route jenkins -o jsonpath="{.status.ingress[0].host}")`

As a precaution, please output the `ADDR` variable and check whether the address looks correct.

```bash
echo $ADDR
```

Now we can open Jenkins UI.

```bash
open "http://$ADDR"
```

This time there is no need even to login. All we need to do is to check whether changing the tag worked. Please observe the version in the bottom-right corner of the screen. If should be *Jenkins ver. 2.112*.

## Upgrading Helm Installations

Let's imagine that some time passed and we decided to upgrade our Jenkins from *2.112* to *2.116*. We go through the documentation and discover that there is the `upgrade` command we can leverage.

```bash
helm upgrade jenkins stable/jenkins \
    --set Master.ImageTag=2.116-alpine \
    --reuse-values
```

This time we did not specify the Namespace but we did set the `--reuse-values` argument. With it, the upgrade will maintain all the values used the last time we installed or upgraded the Chart. The result is an upgrade of the Kubernetes resources so that they comply with our desire to change the tag, and leave everything else intact.

The output of the `upgrade` command, limited to the first few lines, is as follows.

```
Release "jenkins" has been upgraded. Happy Helming!
LAST DEPLOYED: Thu May 24 12:51:03 2018
NAMESPACE: jenkins
STATUS: DEPLOYED
...
```

We can see that the release was upgraded.

To be on the safe side, we'll describe the `jenkins` Deployment and confirm that the image is indeed `2.116-alpine`.

```bash
kubectl -n jenkins \
    describe deployment jenkins
```

The output, limited to the relevant parts, is as follows.

```
Name:              jenkins
Namespace:         jenkins
...
Pod Template:
  ...
  Containers:
   jenkins:
    Image: jenkins/jenkins:2.116-alpine
    ...
```

The image was indeed updated to the tag `2.116-alpine`.

To satisfy my paranoid nature, we'll also open Jenkins UI and confirm the version there. But, before we do that, we need to wait until the update rolls out.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

Now we can open Jenkins UI.

```bash
open "http://$ADDR"
```

Please note the version in the bottom-right corner of the screen. It should say *Jenkins ver. 2.116*.

## Rolling Back A Helm Revision

No matter how we deploy our applications and no matter how much we trust our validations, the truth is that sooner or later we'll have to roll back. That is especially true with third-party applications. While we could roll forward faulty applications we developed, the same is often not an option with those that are not in our control. If there is a problem and we cannot fix it fast, the only alternative it to roll back.

Fortunately, Helm provides a mechanism to roll back. Before we try it out, let's take a look at the list of the Charts we installed so far.

```bash
helm list
```

The output is as follows.

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 2        Thu May ... DEPLOYED jenkins-0.16.1 jenkins  
```

As expected, we have only one Chart running in our cluster. The important piece of information is that it is the second revision. First we installed the Chart with Jenkins version 2.112, and then we upgraded it to 2.116.

W> ## A note to minikube users
W>
W> You'll see `3` revisions in your output. We executed `helm upgrade` after the initial install to change the type of the `jenkins` Service to `NodePort`.

We can roll back to the the previous version (`2.112`) by executing `helm rollback jenkins 1`. That would roll back from the revision `2` to whatever was defined as the revision `1`. However, in most cases that is unpractical. Most of our rollbacks are likely to be executed through our CD or CDP processes. In those cases, it might be too complicated for us to find out what was the previous release number.

Luckily, there is an undocumented feature that allows us to roll back to the previous version without explicitly setting up the revision number. By the time you read this, the feature might become documented. I was about to start working on it and submit a pull request. Luckily, while going through the code I saw that it's already there.

Please execute the command that follows.

```bash
helm rollback jenkins 0
```

By specifying `0` as the revision number, Helm will roll back to the previous version. It's as easy as that.

We got the visual confirmation in form of the "`Rollback was a success! Happy Helming!`" message.

Let's take a look at the current situation.

```bash
helm list
```

The output is as follows.

```
NAME   	REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins	3        Thu May ... DEPLOYED jenkins-0.16.1 jenkins  
```

We can see that even though we issued a rollback, Helm created a new revision `3`. There's no need to panic. Every change is a new revision, even when a change means re-applying definition from one of the previous releases.

To be on the safe side, we'll go back to Jenkins UI and confirm that we are using version `2.112` again.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$ADDR"
```

We waited until Jenkins rolled out, and opened it in our favorite browser. If we look at the version information located in the bottom-right corner of the screen, we are bound to discover that it is *Jenkins ver. 2.112* once again.

We are about to start over one more time, so our next step it to purge Jenkins.

```bash
helm delete jenkins --purge
```

## Using YAML Values To Customize Helm Installations

We managed to customize Jenkins by setting `ImageTag`. What if we'd like to set CPU and memory. We should also add Ingress and that would require a few annotations. If we add Ingress, we might want to change the Service type to ClusterIP and set HostName to our domain. We should also make sure that RBAC is used. Finally, the plugins that come with the Chart are probably not all the plugins we need.

Applying all those changes through `--set` arguments would end up as a very long command and would constitute an undocumented installation. We'll have to change the tactic and switch to `--values`. But before we do all that, we need to generate a domain we'll use with our cluster.

We'll use [xip.io](http://xip.io/) to generate valid domains. The service provides a wildcard DNS for any IP address. It extracts IP from the xip.io subdomain and sends it back in the response. For example, if we generate 192.168.99.100.xip.io, it'll be resolved to 192.168.99.100. We can even add sub-sub domains like something.192.168.99.100.xip.io and it would still be resolved to 192.168.99.100. It's a simple and awesome service that quickly became indispensable part of my toolbox.

First things first... We need to find out the IP of our cluster or external LB if available. The commands that follow will differ from one cluster type to another.

I> Feel free to skip the sections that follow if you already know how to get the IP of your cluster's entry point.

If your cluster is running in **AWS** and was created with **kops**, we'll need to retrieve the hostname from the Ingress Service, and extract the IP from it. Please execute the commands that follow.

```bash
LB_HOST=$(kubectl -n kube-ingress \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

LB_IP="$(dig +short $LB_HOST \
    | tail -n 1)"
```

If your cluster is running in **Docker For Mac/Windows**, the IP is `127.0.0.1` and all you have to do is assign it to the environment variable `LB_IP`. Please execute the command that follows.

```bash
LB_IP="127.0.0.1"
```

If your cluster is running in **minikube**, the IP is can be retrieved using `minikube ip` command. Please execute the command that follows.

```bash
LB_IP="$(minikube ip)"
```

If your cluster is running in **GKE**, the IP is can be retrieved from the Ingress Service. Please execute the command that follows.

```bash
LB_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
```

Next we'll output the retrieved IP to confirm that the commands worked, and generate a sub-sub domain `jenkins`.

```bash
echo $LB_IP

HOST="jenkins.$LB_IP.xip.io"

echo $HOST
```

The output of the second `echo` command should be similar to the one that follows.

```
jenkins.192.168.99.100.xip.io
```

*xip.io* will resolve that address to `192.168.99.100` and we'll have a unique domain for our Jenkins installation. That way we can stop using different paths to distinguish applications in Ingress config. Domains work much better. Many Helm charts do not even have the option to configure unique request paths and assume that Ingress will be configured through a unique domain.

W> ## A note to minishift users
W>
W> I did not forget about you. You already have a valid domain in the `ADDR` variable. It is based on *nip.io* which serves the same purpose as *xip.io*. All we have to do is assign it to the `HOST` variable. Please execute the command that follows.
W> 
W> `HOST=$ADDR && echo $HOST`.
W> 
W> The output should be similar to `jenkins.192.168.99.100.nip.io`.

Now that we have a valid `jenkins.*` domain, we can try to figure out how to apply all the changes we discussed.

We already learned that we can inspect all the available values using `helm inspect` command. Let's take another look.

```bash
helm inspect values stable/jenkins
```

The output, limited to the relevant parts, is as follows.

```yaml
Master:
  Name: jenkins-master
  Image: "jenkins/jenkins"
  ImageTag: "lts"
  ...
  Cpu: "200m"
  Memory: "256Mi"
  ...
  ServiceType: LoadBalancer
  # Master Service annotations
  ServiceAnnotations: {}
  ...
  # HostName: jenkins.cluster.local
  ...
  InstallPlugins:
    - kubernetes:1.1
    - workflow-aggregator:2.5
    - workflow-job:2.15
    - credentials-binding:1.13
    - git:3.6.4
  ...
  Ingress:
    ApiVersion: extensions/v1beta1
    Annotations:
    ...
...
rbac:
  install: false
  ...
```

Everything we need to accomplish our new requirements is available through the values. Some of them are already filled with defaults, while others are commented. When we look at all those values, it becomes clear that it would be unpractical to try to re-define them all through `--set` arguments. We'll use `--values` instead. It will allow us to specify the values in a file.

I already prepared a YAML file with the values that will fullfil our requirements, so let's take a quick look at them.

```bash
cat helm/jenkins-values.yml
```

The output is as follows.

```yaml
Master:
  ImageTag: "2.116-alpine"
  Cpu: "500m"
  Memory: "500Mi"
  ServiceType: ClusterIP
  ServiceAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
  InstallPlugins:
    - blueocean:1.5.0
    - credentials:2.1.16
    - ec2:1.39
    - git:3.8.0
    - git-client:2.7.1
    - github:1.29.0
    - kubernetes:1.5.2
    - pipeline-utility-steps:2.0.2
    - script-security:1.43
    - slack:2.3
    - thinBackup:1.9
    - workflow-aggregator:2.5
  Ingress:
    Annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      ingress.kubernetes.io/ssl-redirect: "false"
      ingress.kubernetes.io/proxy-body-size: 50m
      ingress.kubernetes.io/proxy-request-buffering: "off"
  HostName: jenkins.acme.com
rbac:
  install: true
```

As you can see, the variables in that file follow the same format as those we output through the `helm inspect values` command. The only difference is in values, and the fact that `helm/jenkins-values.yml` contains only those that we are planning to change.

We defined that the `ImageTag` should be fixed to `2.116-alpine`.

We specified that our Jenkins master will need half a CPU and 500 MB RAM. The default values of 0.2 CPU and 256 MB RAM are probably not enough. What we set is also low, but since we're not going to run any serious load (at least not yet), what we re-defined should be enough.

The service was changed to `ClusterIP` to better accomodate Ingress resource we're defining further down.

If you are not using AWS, you can ignore `ServiceAnnotations`. They're telling ELB to use HTTP protocol.

Further down, we are defining the plugins we'll use throughout the book. Their usefulness will become evident in the next chapters.

The values in the `Ingress` section are defining the annotations that tell Ingress not to redirect HTTP requests to HTTPS (we don't have SSL certificates), as well as a few other less important options. We set both the old style (`ingress.kubernetes.io`) and the new style (`nginx.ingress.kubernetes.io`) of defining NGINX Ingress. That way it'll work no matter which Ingress version you're using. The `HostName` is set to a value that obviously does not exist. I could not know in advance what will be your hostname, so we'll overwrite it later on.

Finally, we set `rbac.install` to `true` so that the Chart knows that it should set the proper permissions.

Having all those variables defined at once might be a bit overwhelming. You might want to go through the [Jenkins Chart documentation](https://hub.kubeapps.com/charts/stable/jenkins) for more info. In some cases documentation alone is not enough and I often end up going through the files that form the chart. You'll get a grip on them with time. For now, the important thing to observe is that we can re-define any number of variables through a YAML file.

Let's install the Chart with those variables.

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml \
    --set Master.HostName=$HOST
```

We used the `--values` argument to pass the contents of the `helm/jenkins-values.yml`. Since we had to overwrite the `HostName`, we used `--set`. If the same value is defined through `--values` and `--set`, the latter always takes precedence.

W> ## A note to minishift users
W>
W> The values define Ingress which does not exist in your cluster. If we'd create a set of values specifically for OpenShift, we would not define Ingress. However, since those values are supposed to work in any Kubernetes cluster, we left them intact. Given that Ingress controller does not exist, Ingress resources will have no effect so it's safe to leave those values.

Next, we'll wait for `jenkins` Deployment to roll out and open its UI in a browser.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$HOST"
```

The fact that we opened Jenkins through a domain defined as Ingress (or Route in case of OpenShift) tells us that the values were indeed used. We can double check those currently defined for the installed Chart with the command that follows.

```bash
helm get values jenkins
```

The output is as follows.

```yaml
Master:
  Cpu: 500m
  HostName: jenkins.18.220.212.56.xip.io
  ImageTag: 2.116-alpine
  Ingress:
    Annotations:
      ingress.kubernetes.io/proxy-body-size: 50m
      ingress.kubernetes.io/proxy-request-buffering: "off"
      ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
  InstallPlugins:
  - blueocean:1.5.0
  - credentials:2.1.16
  - ec2:1.39
  - git:3.8.0
  - git-client:2.7.1
  - github:1.29.0
  - kubernetes:1.5.2
  - pipeline-utility-steps:2.0.2
  - script-security:1.43
  - slack:2.3
  - thinBackup:1.9
  - workflow-aggregator:2.5
  Memory: 500Mi
  ServiceAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
  ServiceType: ClusterIP
rbac:
  install: true
```

Even though the order is slightly different, we can easily confirm that the values are the same as those we defined in `helm/jenkins-values.yml`. The exception is the `HostName` which was overwritten through the `--set` argument.

Now that we explored how to use Helm to deploy publicly available Charts, we'll turn our attention towards development. Can we leverage the power behind Charts for our applications?

Before we proceed, please delete the Chart we installed as well as the `jenkins` Namespace.

```bash
helm delete jenkins --purge

kubectl delete ns jenkins
```

## Creating Helm Charts

Our next goal is to create a Chart for the *go-demo-3* application. We'll use the fork you created in the previous chapter.

First we'll move into the fork's directory.

```bash
cd ../go-demo-3
```

To be on the safe side, we'll push the changes you might have made in the previous chapter and than we'll sync your fork with the upstream repository. That way we'll guarantee that you have all the changes I might have made.

You probably already know how to push your changes and how to sync with the upstream repository. In case you don't, the commands are as follows.

```bash
git add .

git commit -m \
    "Defining Continuous Deployment chapter"

git push

git remote add upstream \
    https://github.com/vfarcic/go-demo-3.git

git fetch upstream

git checkout master

git merge upstream/master
```

We pushed the changes we made in the previous chapter, we fetched the upstream repository *vfarcic/go-demo-3*, and we merged the latest code from it. Now we are ready to create our first Chart.

Even though we could create a Chart from scratch by creating a specific folder structure and the required files, we'll take a shortcut and create a sample Chart that can be modified later to suit our needs.

We won't start with a Chart for the *go-demo-3* application. Instead, we'll create a creatively named Chart *my-app* that we'll use to get a basic understanding of the commands we can use to create and manage our Charts. Once we're familiar with the process, we'll switch to *go-demo-3*.

Here we go.

```bash
helm create my-app

ls -1 my-app
```

The first command created a Chart named *my-app*, and the second listed the files and the directories that form the new Chart.

The output of the latter command is as follows.

```
Chart.yaml
charts
templates
values.yaml
```

We will not go into the details behind each of those files and directories just yet. For now, just note that a Chart consists of files and directories that follow certain naming conventions.

If our Chart has dependencies, we could download them with the `dependency update` command.

```bash
helm dependency update my-app
```

The output shows that `no requirements` were `found in .../go-demo-3/my-app/charts`. That makes sense because we did not yet declare any dependencies. For now, just remember that they can be downloaded or updated.

Once we're done with defining the Chart of an application, we can package it.

```bash
helm package my-app
```

We can see from the output that Helm `successfully packaged chart and saved it to: .../go-demo-3/my-app-0.1.0.tgz`. We do not yet have a repository for our Charts. We'll work on that in the next chapter.

If we are unsure whether we made a mistake in our Chart, we can validate it by executing `lint` command.

```bash
helm lint my-app
```

The output is as follows.

```
==> Linting my-app
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

We can see that our Chart contains no failures, at least not those based on syntax. That should come as no surprise since we did not even modify the sample Chart Helm created for us.

Charts can be installed using a Chart repository (e.g., `stable/jenkins`), a local Chart archive (e.g., `my-app-0.1.0.tgz`), an unpacked Chart directory (e.g., `my-app`), or a full URL (e.g., `https://acme.com/charts/my-app-0.1.0.tgz`). So far we used Chart repository to install Jenkins. We'll switch to the local archive option to install `my-app`.

```bash
helm install ./my-app-0.1.0.tgz \
    --name my-app
```

The output is as follows.

```
NAME:   my-app
LAST DEPLOYED: Thu May 24 13:43:17 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME   TYPE      CLUSTER-IP     EXTERNAL-IP PORT(S) AGE
my-app ClusterIP 100.65.227.236 <none>      80/TCP  1s

==> v1beta2/Deployment
NAME   DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
my-app 1       1       1          0         1s

==> v1/Pod(related)
NAME                    READY STATUS            RESTARTS AGE
my-app-7f4d66bf86-dns28 0/1   ContainerCreating 0        1s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=my-app,release=my-app" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

The sample application is a very simple one with a Service and a Deployment. There's not much to say about it. We used it only to explore the basic commands for creating and managing Charts. We'll delete everything we did and start over with a more serious example.

```bash
helm delete my-app --purge

rm -rf my-app

rm -rf my-app-0.1.0.tgz
```

We deleted the Chart from the cluster, as well as the local directory and the archive we created earlier. The time has come to apply the knowledge we obtained and explore the format of the files that constitute a Chart. We'll switch to the *go-demo-3* application next.

## Exploring Files That Constitute A Chart

I prepared a Chart that defines the *go-demo-3* application. We'll use it to get familiar with writing Charts. Even if we choose to use Helm only for third-party applications, familiarity with Chart files is a must since we might have to look at them to better understand the application we want to install.

The files are located in `helm/go-demo-3` directory inside the repository. Let's take a look at what we have.

```bash
ls -1 helm/go-demo-3
```

The output is as follows.

```
Chart.yaml
LICENSE
README.md
templates
values.yaml
```

A chart is organized as a collection of files inside a directory. The directory name is the name of the chart (without versioning information). So, a Chart that describes *go-demo-3* is stored in the directory with the same name.

The first file we'll explore is *Chart.yml*. It is a mandatory file with a combination of mandatory and optional fields.

Let's take a closer look.

```bash
cat helm/go-demo-3/Chart.yaml
```

The output is as follows.

```yaml
name: go-demo-3
version: 0.0.1
apiVersion: v1
description: A silly demo based on API written in Go and MongoDB
keywords:
- api
- backend
- go
- database
- mongodb
home: http://www.devopstoolkitseries.com/
sources:
- https://github.com/vfarcic/go-demo-3
maintainers:
- name: Viktor Farcic
  email: viktor@farcic.com
```

The `name`, `version`, and `apiVersion` are mandatory fields. All the others are optional.

Even though most of the fields should be self-explanatory, we'll go through each of them just in case.

The `name` is the name of the Chart and the `version` is the version. That's obvious, isn't it? The important thing to note is that versions must follow [SemVer 2](http://semver.org/) standard. The full identification of a Chart package in a repository is always a combination of a name and a version. If we package this Chart, its name would be *go-demo-3-0.0.1.tgz*. The `apiVersion` is the version of the Helm API and, at this moment, the only supported value is `v1`.

The rest of the fields are mostly informational. You should be able to understand their meaning, so I won't bother you with lengthy explanations.

The next in line is the LICENSE file.

```bash
cat helm/go-demo-3/LICENSE
```

The first few lines of the output are as follows.

```
The MIT License (MIT)

Copyright (c) 2018 Viktor Farcic

Permission is hereby granted, free ...
```

The *go-demo-3* application is licensed as MIT. It's up to you to decide which license you'll use, if any.

README.md is used to describe the application.

```bash
cat helm/go-demo-3/README.md
```

The output is as follows.

```
This is just a silly demo.
```

I was too lazy to write a proper description. You shouldn't be. As a rule of thumb, README.md should contain a description of the application, a list of the pre-requisites and the requirements, a description of the options available through values.yaml, and anything else you might deem important. As the extension suggests, it should be written in Markdown format.

Now we are getting to the important part.

The values that can be used to customize the installation are defined in `values.yaml`.

```bash
cat helm/go-demo-3/values.yaml
```

The output is as follows.

```yaml
replicaCount: 3
dbReplicaCount: 3
image:
  tag: latest
  dbTag: 3.3
ingress:
  enabled: true
  host: acme.com
service:
  # Change to NodePort if ingress.enable=false
  type: ClusterIP
rbac:
  enabled: true
resources:
  limits:
   cpu: 0.2
   memory: 20Mi
  requests:
   cpu: 0.1
   memory: 10Mi
dbResources:
  limits:
    memory: "200Mi"
    cpu: 0.2
  requests:
    memory: "100Mi"
    cpu: 0.1
dbPersistence:
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # storageClass: "-"
  accessMode: ReadWriteOnce
  size: 2Gi
```

As you can see, all the things that may vary from one *go-demo-3* installation to another are defined here. We can set how many replicas should be deployed for both the API and the DB. Tags of both can be changed as well. We can disable Ingress and change the host. We can change the type of the Service or disable RBAC. The resources are split into two groups, so that the API and the DB can be controlled separately. Finally, we can change database persistence by specifying the `storageClass`, the `accessMode`, or the `size`.

I should have described those values in more detail in `README.md`, but, as I already admitted, I was too lazy to do that. The alternative explanation of the lack of proper README is that we'll go through the YAML files where those values are used and everything will become much clearer.

The important thing to note is that the values defined in that file are defaults that are used only if we do not overwrite them during the installation through `--set` or `--values` arguments.

The files that define all the resources are in the `templates` directory.

```bash
ls -1 helm/go-demo-3/templates/
```

The output is as follows.

```
NOTES.txt
_helpers.tpl
deployment.yaml
ing.yaml
rbac.yaml
sts.yaml
svc.yaml
```

The templates are written in [Go template language](https://golang.org/pkg/text/template/) extended with add-on functions from [Sprig library](https://github.com/Masterminds/sprig) and a few others specific to Helm. Don't worry if you are new to Go. You will not need to learn it. For most use-cases, a few templating rules are more than enough for most of the use-cases. With time, you might decide to "go crazy" and learn everything templating offers. That time is not today.

When Helm renders the Chart, it'll pass all the files in the `templates` directory through its templating engine.

Let's take a look at the `NOTES.txt` file.

```bash
cat helm/go-demo-3/templates/NOTES.txt
```

The output is as follows.

```
1. Wait until the applicaiton is rolled out:
  kubectl -n {{ .Release.Namespace }} rollout status deployment {{ template "helm.fullname" . }}

2. Test the application by running these commands:
{{- if .Values.ingress.enabled }}
  curl http://{{ .Values.ingress.host }}/demo/hello
{{- else if contains "NodePort" .Values.service.type }}
  export PORT=$(kubectl -n {{ .Release.Namespace }} get svc {{ template "helm.fullname" . }} -o jsonpath="{.spec.ports[0].nodePort}")

  # If you are running Docker for Mac/Windows
  export ADDR=localhost

  # If you are running minikube
  export ADDR=$(minikube ip)

  # If you are running anything else
  export ADDR=$(kubectl -n {{ .Release.Namespace }} get nodes -o jsonpath="{.items[0].status.addresses[0].address}")

  curl http://$NODE_IP:$PORT/demo/hello
{{- else }}
  If the application is running in OpenShift, please create a Route to enable access.

  For everyone else, you set ingress.enabled=false and service.type is not set to NodePort. The application cannot be accessed from outside the cluster.
{{- end }}
```

The content of the NOTES.txt file will be printed after the installation or upgrade. You already saw a similar one in action when we installed Jenkins. The instructions we received how to open it and how to retrieve the password came from the NOTES.txt file stored in Jenkins Chart.

That file is our first direct contact with Helm templating. You'll notice that parts of it are inside `if/else` blocks. If we take a look at the second bullet, we can deduce that one set of instructions will be printed if `ingress` is `enabled`, another if the `type` of the Service is `NodePort`, and yet another if neither of the first two conditions are met.

Template snippets are always inside double curly braces (e.g., `{{` and `}}`). Inside them can be (often simple) logic like an `if` statement, as well as predefined and custom made function. An example of a custom made function is `{{ template "helm.fullname" . }}`. It is defined in `_helpers.tpl` file which we'll explore soon.

Variables always start with a dot (`.`). Those coming from the `values.yaml` file are always prefixed with `.Values`. An example is `.Values.ingress.host` that defines the `host` that will be configured in our Ingress resource.

Helm also provides a set of pre-defined variables prefixed with `.Release`, `.Chart`, `.Files`, and `.Capabilities`. As an example, near the top of the NOTES.txt file is `{{ .Release.Namespace }}` snippet that will get converted to the Namespace into which we decided to install our Chart. 

The full list of the pre-defined values is as follows (a copy from the official documentation).

* `Release.Name`: The name of the release (not the Chart)
* `Release.Time`: The time the chart release was last updated. This will match the Last Released time on a Release object.
* `Release.Namespace`: The Namespace the Chart was released to.
* `Release.Service`: The service that conducted the release. Usually this is Tiller.
* `Release.IsUpgrade`: This is set to `true` if the current operation is an upgrade or rollback.
* `Release.IsInstall`: This is set to `true` if the current operation is an install.
* `Release.Revision`: The revision number. It begins at 1, and increments with each helm upgrade.
* `Chart`: The contents of the Chart.yaml. Thus, the Chart version is obtainable as Chart.Version and the maintainers are in Chart.Maintainers.
* `Files`: A map-like object containing all non-special files in the Chart. This will not give you access to templates, but will give you access to additional files that are present (unless they are excluded using .helmignore). Files can be accessed using `{{index .Files "file.name"}}` or using the `{{.Files.Get name}}` or `{{.Files.GetString name}}` functions. You can also access the contents of the file as `[]byte` using `{{.Files.GetBytes}}`
* `Capabilities`: A map-like object that contains information about the versions of Kubernetes (`{{.Capabilities.KubeVersion}}`, Tiller (`{{.Capabilities.TillerVersion}}`, and the supported Kubernetes API versions (`{{.Capabilities.APIVersions.Has "batch/v1"}}`)

You'll also notice that our `if`, `else if`, `else`, and `end` statements start with a dash (`-`). That's the Go template way of specifying that we want all empty space before the statement (when `-` is on the left) or after the statement (when `-` is on the right) to be removed.

There's much more to Go templating that what we just explored. I'll comment on other use-cases as they come. For now, this should be enough to get you going. You are free to consult [template package documentation](https://golang.org/pkg/text/template/) for more info. For now, the important thing to note is that we have the `NOTES.txt` file that will provide useful post-installation information to those who will use our Chart.

I mentioned `_helpers.tpl` as the source of custom functions and variables. Let's take a look at it.

```bash
cat helm/go-demo-3/templates/_helpers.tpl
```

The output is as follows.

```
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
```

That file is the exact copy of the `_helpers.tpl` file that was created with the `helm create` command that generated a sample Chart. You can extend it with your own functions. I didn't. I kept it as-is. It consists of two functions with comments that describe them. The first (`helm.name`) returns the name of the chart trimmed to 63 characters which is the limitation for the size of some of the Kubernetes fields. The second function (`helm.fullname`) returns fully qualified name of the application. If you go back to the NOTES.txt file, you'll notice that we are using `helm.fullname` in a few occasions. Later on, you'll see that we'll use it in quite a few other places.

Now that NOTES.txt and _helpers.tpl are out of the way, we can take a look at the first template that defines one of the Kubernetes resources.

```bash
cat helm/go-demo-3/templates/deployment.yaml
```

The output is as follows.

```yaml
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: {{ template "helm.fullname" . }}
  labels:
    app: {{ template "helm.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ template "helm.name" . }}
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ template "helm.name" . }}
        release: {{ .Release.Name }}
    spec:
      containers:
      - name: api
        image: "vfarcic/go-demo-3:{{ .Values.image.tag }}"
        env:
        - name: DB
          value: {{ template "helm.fullname" . }}-db
        readinessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
          periodSeconds: 1
        livenessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
        resources:
{{ toYaml .Values.resources | indent 10 }}
```

That file defines the Deployment of the *go-demo-3* API. The first thing I did was to copy the definition from the YAML file we used in the previous chapters. Afterwards, I replaced parts of it with functions and variables. The `name`, for example, is now `{{ template "helm.fullname" . }}`, which guarantees that this Deployment will have a unique name. The rest of the file follows the same logic. Some things are using pre-defined values like `{{ .Chart.Name }}` and `{{ .Release.Name }}`, while others are using those from the `values.yaml`. An example of the latter is `{{ .Values.replicaCount }}`.

The last line contains a syntax we haven't seen before. `{{ toYaml .Values.resources | indent 10 }}` will take all the entries from the `resources` field in the `values.yaml`, and convert them to YAML format. Since the final YAML needs to be properly indented, we piped the output to `indent 10`. Since the `resources:` section of `deployment.yaml` is indented by eight spaces, indenting the entries from `resources` in `values.yaml` by ten will put them just two spaces inside it.

Let's take a look at one more template.

```bash
cat helm/go-demo-3/templates/ing.yaml
```

The output is as follows.

```yaml
{{- if .Values.ingress.enabled -}}
{{- $serviceName := include "helm.fullname" . -}}
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ template "helm.fullname" . }}
  labels:
    app: {{ template "helm.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: {{ $serviceName }}
          servicePort: 8080
    host: {{ .Values.ingress.host }}
{{- end -}}
```

That YAML defines the Ingress resource that makes the API Deployment accessible through its Service. Most of the values are the same as in the Deployment. There's only one difference worthwhile commenting.

The whole YAML is enveloped in the `{{- if .Values.ingress.enabled -}}` statement. The resource will be installed only if `ingress.enabled` values is set to `true`. Since that is already the default value in `values.yaml`, we'll have to explicitly disable it if we do not want Ingress.

Feel free to explore the rest of the templates. They are following the same logic as the two we just described.

There's one potentially important file we did not define. We have not created `requirements.yaml` for *go-demo-3*. We did not need any. We will use it though in one of the next chapters, so I'll save the explanation for later.

Now that we went through the files that constitute the *go-demo-3* Chart, we should `lint` it to confirm that the format does not contain any obvious issues.

```bash
helm lint helm/go-demo-3
```

The output is as follows.

```
==> Linting helm/go-demo-3
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

If we ignore the complaint that the icon is not defined, our Chart seems to be defined correctly, and we can create a package.

```bash
helm package helm/go-demo-3 -d helm
```

The output is as follows.

```
Successfully packaged chart and saved it to: helm/go-demo-3-0.0.1.tgz
```

The `-d` argument is new. It specified that we want to create a package in `helm` directory.

We will not use the package just yet. For now, I wanted to make sure that you remember that we can create it.

## Upgrading Charts

We are about to install the *go-demo-3* Chart. You should already be familiar with the commands, so you can consider this as an exercise that aims to solidify what you already learned. There will be one difference when compared to the commands we executed earlier. It'll prove to be a simple, but important one for our continuous deployment processes.

We'll start by inspecting the values.

```bash
helm inspect values helm/go-demo-3
```

The output is as follows.

```yaml
replicaCount: 3
dbReplicaCount: 3
image:
  tag: latest
  dbTag: 3.3
ingress:
  enabled: true
  host: acme.com
route:
  enabled: true
service:
  # Change to NodePort if ingress.enable=false
  type: ClusterIP
rbac:
  enabled: true
resources:
  limits:
   cpu: 0.2
   memory: 20Mi
  requests:
   cpu: 0.1
   memory: 10Mi
dbResources:
  limits:
    memory: "200Mi"
    cpu: 0.2
  requests:
    memory: "100Mi"
    cpu: 0.1
dbPersistence:
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # storageClass: "-"
  accessMode: ReadWriteOnce
  size: 2Gi
```

We are almost ready to install the application. The only thing we're missing is the host we'll use for the application.

You'll find two commands below. Please execute only one of those depending on your Kubernetes flavor.

If you are **NOT** using **minishift**, please execute the command that follows.

```bash
HOST="go-demo-3.$LB_IP.xip.io"
```

If you are using minishift, you can retrieve the host with the command that follows.

```bash
HOST="go-demo-3-go-demo-3.$(minishift ip).nip.io"
```

No matter how you retrieved the host, we'll output it so that we can confirm that it looks OK.

```bash
echo $HOST
```

In my case, the output is as follows.

```
jenkins.192.168.99.100.xip.io
```

Now we are finally ready to install the Chart. However, we won't use `helm install` as before. We'll use `upgrade` instead.

```bash
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=1.0 \
    --set ingress.host=$HOST \
    --reuse-values
```

The reason we are using `helm upgrade` this time lies in the fact that we are practicing the commands we hope to use inside our CDP processes. Given that we want to use the same process no matter whether it's the first release (install) or those that follow (upgrade). It would be silly to have `if/else` statements that would determine whether it is the first release and thus execute the install, or to go with upgrade. We are going with a much simpler solution. We will always upgrade the Chart. The trick is in the `-i` argument that can be translated to "install unless a release by the same name doesn't already exist".

The next two arguments are the name of the Chart (`go-demo-3`) and the path to the Chart (`helm/go-demo-3`). By using the path to the directory with the Chart, we are experiencing yet another way to supply the Chart files. In the next chapter will switch to using `tgz` packages.

The rest of the arguments are making sure that the correct tag is used (`1.0`), that Ingress is using the desired host, and that the values that might have been used in the previous upgrades are still the same (`--reuse-values`).

If this command is used in the continuous deployment processes, we would need to set the tag explicitly through the `--set` argument to ensure that the correct image is used. The host, on the other hand, is static and unlikely to change often (if ever). We would be better of defining it in `values.yaml`. However, since I could not predict what will be your host, we had to define it as the `--set` argument.

Please note that minishift does not support Ingress (at least not by default). So, it was created but it has no effect. I though that it is a better option than to use different commands for OpenShift than for the rest of the flavors. If minishift is your choice, feel free to add `--set ingress.enable=false` to the previous command.

The output of the `upgrade` is the same as if we executed `install` (resources are removed for brevity).

```
NAME:   go-demo-3
LAST DEPLOYED: Fri May 25 14:40:31 2018
NAMESPACE: go-demo-3
STATUS: DEPLOYED

...

NOTES:
1. Wait until the applicaiton is rolled out:
  kubectl -n go-demo-3 rollout status deployment go-demo-3

2. Test the application by running these commands:
  curl http://go-demo-3.18.222.53.124.xip.io/demo/hello
```

W> ## A note to minishift users
W>
W> We'll need to create a Route separately from the Helm Chart, just as we did with Jenkins. Please execute the command that follows.
W>
W> `oc -n go-demo-3 create route edge --service go-demo-3 --insecure-policy Allow`

We'll wait until the Deployment rolls out before proceeding.

```bash
kubectl -n go-demo-3 \
    rollout status deployment go-demo-3
```

The output is as follows.

```
Waiting for rollout to finish: 0 of 3 updated replicas are available...
Waiting for rollout to finish: 1 of 3 updated replicas are available...
Waiting for rollout to finish: 2 of 3 updated replicas are available...
deployment "go-demo-3" successfully rolled out
```

Now we can confirm that the application is indeed working by sending a `curl` request.

```bash    
curl http://$HOST/demo/hello
```

The output should display the familiar `hello, world!` message, thus confirming that the application is indeed running and that it is accessible through the host we defined in Ingress (or Route in case of minishift).

Let's imagine that some time passed since we installed the first release, that someone pushed a change to the master branch, that we already run all our tests, that we built a new image, and that we pushed it to Docker Hub. In that hypothetical situation, our next step would be to execute another `helm upgrade`.

```bash
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=2.0 \
    --reuse-values
```

When compared with the previous command, the difference is in the tag. This time we set it to `2.0`. We also removed `--set ingress.host=$HOST` argument. Since we have `--reuse-values`, all those used in the previous release will be maintained.

There's probably no need to further validations (e.g., wait for it to roll out and send a `curl` request). All that's left is to remove the Chart and delete the Namespace. We're done with the hands-on exercises.

```bash
helm delete go-demo-3 --purge

kubectl delete ns go-demo-3
```

## Helm vs OpenShift Templates

I could give you a lengthy comparison between Helm and OpenShift templates. I won't do that. The reason is simple. Helm is the de-facto standard for installing applications. It's the most widely used, and it's adoption is going through the roof. Among the similar tools, it has the biggest community, it has the most applications available, and it is becoming adopted by more software vendors than any other solution. The exception is RedHat. They created OpenShift templates long before Helm came into being. Helm borrowed many of its concepts, improved them, and added a few additional features. When we add to that the fact that OpenShift templates work only on OpenShift, the decision which one to use is pretty straight forward. Helm wins, unless you chose OpenShift as your Kubernetes flavor. In that case, the decision is harder to make. On the one hand, Routes and a few other OpenShift-specific types of resources cannot be defined (easily) in Helm. On the other hand, it is likely that OpenShift will switch to Helm at some moment. So, you might just as well jump into Helm right away.

I must give a big thumbs up to RedHat for paving the way towards some of the Kubernetes resources that are in use today. They created Routes when Ingress did not exist. They developed OpenShift templates before Helm was created. Both Ingress and Helm were heavily influenced by their counter-parts in OpenShift. The are quite a few other similar examples.

The problem is that RedHat does not want to let go of the things they pioneered. They stick with Routes, even though Ingress become standard. If Routes provide more features than, let's say, nginx Ingress controller, they could still maintain them as OpenShift Ingress (or whatever would be the name). Routes are not the only example. They continue forcing OpenShift templates, even though it's clear that Helm is the de-facto standard. By not switching to the standards that they themselves pioneered, they are making their platform incompatible with others. In the previous chapters we experienced the pain Routes cause when trying to define YAML files that should work on all other Kubernetes flavors. Now we experienced the same problem with Helm.

If you chose OpenShift, it's up to you to decide whether to use Helm or OpenShift templates. Both choices have pros and cons. Personally, one of the things that attracts me the most with Kubernetes is the promise that our applications can run on any hosting solution and on any Kubernetes flavor. RedHat is breaking that promise. It's not that I don't expect different solutions to come up with new things that distinguish them from the competition. I do. OpenShift has quite a few of those. But, it also has features that have equally good or better equivalents that are part of Kubernetes core or widely accepted by the community. Helm is one of those that are better then their counterpart in OpenShift.

We'll continue using Helm throughout the rest of the book. If you do choose to stick with OpenShift templates, you'll have to do a few modifications to the examples. The good news is that those changes should be relatively easy to make. I believe that you won't have a problem adapting.

## What Now?

We have a couple of problems left to solve. We did not yet figure out how to store the Helm charts in a way that they can be easily retrieved and used by others. We'll tackle that issue in the next chapter.

I suggest you take a rest. You deserve it. If you do feel that way, please destroy the cluster. Otherwise, jump to the next chapter right away. The choice is yours.
