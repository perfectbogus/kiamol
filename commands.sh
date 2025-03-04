kubectl run hello-kiamol --image=kiamol/ch02-hello-kiamol --restart=Never

kubectl wait --for=condition=Ready pod hello-kiamol

kubectl get pods

kubectl describe pod hello-kiamol

kubectl get pod hello-kiamol --output custom-columns=Name:metadata.name,NODE_IP:status.hostip,POD_IP:status.podIP

kubectl get pod hello-kiamol -o jsonpath='{.status.containerStatuses[0].containerID}'

docker container ls -q --filter label=io.kubernetes.container.name=hello-kiamol
docker container rm -f $(docker container ls -q --filter label=io.kubernetes.container.name=hello-kiamol)
kubectl get pod hello-kiamol

kubectl run hello-kiamol --image=kiamol/ch02-hello-kiamol --restart=Always

# host-port:pod-port
kubectl port-forward pod/hello-kiamol 8080:80

kubectl create deployment hello-kiamol-2 --image=kiamol/ch02-hello-kiamol

kubectl get deploy hello-kiamol-2 -o jsonpath='{.spec.template.metadata.labels}'
kubectl get deploy hello-kiamol-2 -o jsonpath='{.spec.template.metadata.labels.app}'

kubectl get pods -l app=hello-kiamol-2

kubectl get pods -o custom-columns=NAME:metadata.name,LABELS:metadata.labels
kubectl label pods -l app=hello-kiamol-2 --overwrite app=hello-kiamol-x
# return back the pod to the control of the deployment
kubectl label pods -l app=hello-kiamol-x --overwrite app=hello-kiamol-2
kubectl get pods -l app -o custom-columns=NAME:metadata.name,LABELS:metadata.labels

kubectl port-forward deploy/hello-kiamol-2 8080:80
# deploy the application from the manifest file:
kubectl apply -f https://raw.githubusercontent.com/sixeyed/kiamol/master/ch02/pod.yaml

kubectl apply -f 2_ch/deployment.yaml
kubectl get pods -l app=hello-kiamol-4

kubectl exec -it hello-kiamol -- sh

# print the latest container logs from kubernetes:
kubectl logs --tail=2 hello-kiamol

# make a call to the web app inside the container for the Pod we created
# from the deployment YAML file:
kubectl exec deploy/hello-kiamol-4 -- sh -c 'wget -O - http://localhost > /dev/null'

# Copy the web page from the Pod:
kubectl cp <pod-name>:<pod-path-to-copy> <host-file-to-copy>
kubectl cp hello-kiamol:/usr/share/nginx/html/index.html /tmp/kiamol/ch02/index.html
kubectl cp hello-kiamol:/usr/share/nginx/html/index.html /tmp/index.html

# Delete deploy controller of pods
kubectl delete deploy --all

# Deploy multiple in one command
kubectl apply -f sleep/sleep1.yaml -f sleep/sleep2.yaml
# wait deploy ready
kubectl wait --for=condition=Ready pod -l app=sleep2
# get IP
kubectl get pod -l app=sleep-2 --output jsonpath='{.items[0].status.podIP}'
-> 10.42.0.27
kubectl exec deploy/sleep-1 -- ping -c 2 $(kubectl get pod -l app=sleep-2 --output jsonpath='{.items[0].status.podIP}')
# chec the ip address of replacement pod:
kubectl get pod -l app=sleep-2 --output jsonpath='{.items[0].status.podIP}'
-> 10.42.0.29
# deploy the service defined 
kubectl apply -f sleep/sleep2-service.yaml
# show the basic details of the service:
kubectl get svc sleep-2
# run ping
kubectl exec deploy/sleep-1 -- ping -c 1 sleep-2
# 3.2 Routing traffic between Pods
kubectl apply -f numbers/api.yaml -f numbers/web.yaml
# forward a port to the web app:
kubectl port-forward deploy/numbers-web 8080:80
# deploy the service 
kubectl apply -f numbers/api-service.yaml

kubectl get pod -l app=numbers-api

###############################################################################
# 3.3 Routing external traffic to Pods
###############################################################################
kubectl apply -f sleep/sleep1.yaml -f sleep/sleep2.yaml
kubectl apply -f sleep/sleep2-service.yaml
kubectl apply -f numbers/api.yaml -f numbers/web.yaml
kubectl apply -f numbers/api-service.yaml
kubectl apply -f numbers/web-service.yaml

kubectl get svc numbers-web -o jsonpath='http://{.status.loadBalancer.ingress[0].*}:8080'
kubectl get nodes

# delete the current API Service:
kubectl delete svc numbers-api

# deploy a new ExternalName Service:
kubectl apply -f numbers-services/api-service-externalName.yaml

# run the DNS lookup tool to resolve the Service name:
kubectl exec deploy/sleep-1 -- sh -c 'nslookup numbers-api | tail -n 5'

kubectl delete svc numbers-api

kubectl apply -f numbers-services/api-service-headless.yaml

# verify the DNS lookup:
kubectl exec deploy/sleep-1 -- sh -c 'nslookup numbers-api | grep "^[^*]"'

###
# Understanding Kubernetes Service Resolution
###
kubectl get endpoints sleep-2
kubectl delete pods -l app=sleep-2
kubectl get endpoints sleep-2
kubectl delete deploy sleep-2
kubectl get endpoints sleep-2

kubectl get svc --namespace default
kubectl get svc -n kube-system
kubectl exec deploy/sleep-1 -- sh -c 'nslookup numbers-api.default.svc.cluster.local | grep "^[^*]"'
kubectl exec deploy/sleep-1 -- sh -c 'nslookup kube-dns.kube-system.svc.cluster.local | grep "^[^*]"'

kubectl delete deploy --all
kubectl delete svc --all
kubectl get all

####
# 4: Configuring applications with ConfigMaps and Secrets
####
kubectl apply -f sleep/sleep.yaml
kubectl wait --for=condition=Ready pod -l app=sleep
kubectl exec deploy/sleep -- printenv HOSTNAME KIAMOL_CHAPTER

kubectl create configmap sleep-config-literal --from-literal=kiamol.section='4.1'
kubectl get cm sleep-config-literal
kubectl describe cm sleep-config-literal

####
# 5: Storing data with volumes, mounts and claims
####
kubectl apply -f sleep/sleep.yaml
kubectl exec deploy/sleep -- sh -c 'echo ch05 > file.txt; ls /*.txt'
kubectl get pod -l app=sleep -o jsonpath='{.items[0].status.containerStatuses[0].containerID}'

kubectl exec -it deploy/sleep -- killall5

kubectl get pod -l app=sleep -o jsonpath='{.tems[0].status.containerStatuses[0].containerID}'
kubectl exec deploy/sleep -- ls /*.txt

# EmptyDir Volume
kubectl apply -f sleep/sleep-with-emptyDir.yaml
kubectl exec deploy/sleep -- ls /data
kubectl exec deploy/sleep -- sh -c 'echo ch05 > /data/file.txt; ls /data'
kubectl get pod -l app=sleep -o jsonpath='{.items[0].status.containerStatuses[0].containerID}'
# Kill the container processes
kubectl exec deploy/sleep -- killall5
# Check replacement container ID:
kubectl get pod -l app=sleep -o jsonpath='{.items[0].status.containerStatuses[0].containerID}'
# read the file in the volume:
kubectl exec deploy/sleep -- cat /data/file.txt

# Volume
kubectl apply -f pi/v1/
# wait for the web pod to be ready:
kubectl wait --for=condition=Ready pod -l app=pi-web
# find the app URL from your LoadBalancer:
kubectl get svc pi-proxy -o jsonpath='http://{.status.loadBalancer.ingress[0].*}:8080/?dp=30000'
# Check the cache in the proxy
kubectl exec deploy/pi-proxy -- ls -l /data/nginx/cache
# delete the proxy pod
kubectl delete pod -l app=pi-proxy
# check the cache directory of the replacement pod:
kubectl exec deploy/pi-proxy -- ls -l /data/nginx/cache
# update the proxy pod to use a HostPath volume:
kubectl apply -f pi/nginx-with-hostPath.yaml
# list the contents of the cache directory:
kubectl exec deploy/pi-proxy -- ls -l /data/nginx/cache
# delete the proxy pod:
kubectl delete pod -l app=pi-proxy

# run a pod with a volume mount to the host:
kubectl apply -f sleep/sleep-with-hostPath.yaml
# check the log files inside the container:
kubectl exec deploy/sleep -- ls -l /var/log
# check the logs on the node using the volume:
kubectl exec deploy/sleep -- ls -l /node-root/var/log
# check the container user:
kubectl exec deploy/sleep -- whoami

# Restricting mounts with subpaths
kubectl apply -f sleep/sleep-with-hostPath-subPath.yaml
# check the Pod logs on the node:
kubectl exec deploy/sleep -- sh -c 'ls /pod-logs | grep _pi-'
# check the container logs:
kubectl exec deploy/sleep -- sh -c 'ls /container-logs | grep nginx'

####
# 5.3 Storing clusterwide data with persistent volumes and claims
####
# Create a PV that uses local storage:
# apply a custom label to the first node in your cluster:
kubectl label node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') kiamol=ch05
# check the nodes with a label selector:
kubectl get nodes -l kiamol=ch05
# deploy a PV that uses a local volume on the labeled node:
kubectl apply -f todo-list/persistentVolume.yaml
# check the PV:
kubectl get pv

---
- postgres-persistentVolumeClaim.yaml
apiVersion: v1
kind: persistentVolumeClaim
metadata:
	name: postgres-pvc
spec:
	accessModes:
	 	- ReadWriteOnce
	resources:
		requests:
			storage: 40Mi
	storageClassName: "" # A blank class means a PV needs to exist.

# create a pvc that will bind to the PV:
kubectl apply -f todo-list/postgres-persistentVolumeClaim.yaml
# check PVCs
kubectl get pvc
# check PVs"
kubectl get pv
# Create PVC that doen't match any available PVs:
kubectl apply -f todo-list/postgres-persistentVolumeClaim-too-big.yaml
# check claims
kubectl get pvc
---
spec:
	containers:
		- name: db
		image: postgres:11.6-alpine
		volumeMounts:
			- name: data
			mountPath: /var/lib/postgresql/data
	volumes:
		- name: data
		persistentVolumeClaim: 			# Volume uses a PVC
			claimName: postgres-pvc 	# PVC to use
---
# run the sleep Pod, which has access to the node's disk:
kubectl apply -f sleep/sleep-with-hostPath.yaml
# wait for the Pod to be ready:
kubectl wait --for=condition=Ready pod -l app=sleep
# create the directory path on the node, which the PV expects:
kubectl exec deploy/sleep -- mkdir -p /node-root/volumes/pv01
# deploy the database:
kubectl apply -f todo-list/postgres/
# wait for postgres to initialize:
sleep 30
# chec the database logs:
kubectl logs -l app=todo-db --tail 1
# check the data files in the volume:
kubectl exec deploy/sleep -- sh -c 'ls -l /node-root/volumes/pv01 | grep wal'
# deploy the web app components:
kubectl apply -f todo-list/web
# wait for the web pod:
kubectl wait --for-condition=Ready pod -l app=todo-web
# get the app URL from the Service:
kubectl get svc todo-web -o jsonpath='http://{.status.loadBalancer.ingress[0].*}:8081/new'
# delete the database:
kubectl delete pod -l app=todo-db
# check the contents of the volume on the node:
kubectl exec deploy/sleep -- ls -l /node-root/volumes/pv01/pg_wal

####
# 5.4 Dynamic volume profisioning and storage classes
####
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
	name: postgres-pvc-dynamic
spec:
	accessModes:
		- ReadWriteOnce
	resources:
		requests:
			storage: 100Mi
			# There is no storageClassName field, so this uses the default class.
---
# Dynamically provisioned
# deploy the PVC from listing 5.8:
kubectl apply -f todo-list/postgres-persistentVolumeClaim-dynamic.yaml
# check claims and volumes
kubectl get pvc
kubectl get pv
# delete the claim:
kubectl delete pvc postgres-pvc-dynamic
# check volumes again:
kubectl get pv
# list the storage classes in the cluster:
kubectl get storageclass
# clone the default on windows
chmod +x cloneDefaultStorageClass.sh && ./cloneDefaultStorageClass.sh
# list storage classes
kubectl get sc

####
# 5.5 Understanding storage choices in K8s
####
# delete deployments, PVCs, PVs, and Services:
kubectl delete -f pi/v1 -f sleep/ -f storageClass/ -f todo-list/web -f todo-list/postgres -f todo-list/
# delete the custom storage class
kubectl delete sc kiamol

####
# LAB
####
kubectl apply -f lab/todo-list

--- 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: todo-proxy-lab-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi

-- pvc-todo-web.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: todo-web-lab-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Mi 

####
# 6 Scaling applications across mutiple Pods with controllers
####

# 6.1 How Kubernetes runs apps at scale
---
apiVersion: apps/v1
kind: ReplicaSet				# The spec is almost identical to a Deployment.
metadata:
	name: whoami-web
spec:
	replicas: 1
	selector:					# The selector for the ReplicaSet to find its Pods
		matchLabels:
			app: whoami-web
	template: 					# The usual Pod spec follows.
---
# deploy the ReplicaSet and Service:
kubectl apply -f whoami/
# check the resource
kubectl get replicaset whoami-web
# make an http get call to the Service:
curl $(kubectl get svc whoami-web -o jsonpath='http://{.status.loadBalancer.ingress[0].*}:8088')
# delete all the pods:
kubectl delete pods -l app=whoami-web
# repeat the HTTP call:
curl $(kubectl get svc whoami-web -o jsonpath='http://{.status.loadBalancer.ingress[0].*}:8088')
# show the detail about the ReplicaSet:
kubectl describe rs whoami-web

####
# Scale up
####
kubectl apply -f whoami/update/whoami-replicas-3.yaml
# check pods:
kubectl get pods -l app=whoami-web
# delete all the pods
kubectl delete pods -l app=whoami-web
# check again:
kubectl get pods -l app=whoami-web
# repeat this http call a few times:
curl $(kubectl get svc whoami-web -o jsonpath='http://{.status.loadBalancer.ingress[0].*}:8088')
# run a sleep pod:
kubectl apply -f sleep.yaml
# check the details of the who-am-I service
kubectl get svc whoami-web
# run a DNS lookup for the Service in the sleep Pod:
kubectl exec deploy/sleep -- sh -c 'nslookup whoami-web | grep "^[^*]"'
# make some HTTP calls:
kubectl exec deploy/sleep -- sh -c 'for i in 1 2 3; do curl -w \\n -s http://whoami-web:8088; done;'

####
# Scaling for load with Deployments and ReplicaSet
####
--- web.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pi-web
spec:
  replicas: 2  				# the replicas field is optional; it defaults to 1.
selector:
  matchLabels:
    app: pi-web
  template:						# The Pod spec follows.

---
# deploy the Pi app:
kubectl apply -f pi/web
# Check the ReplicaSet:
kubectl get rs -l app=pi-web
# scale up to more replicas:
kubectl apply -f pi/web/update/web-replicas-3.yaml
# Check the RS:
kubectl get rs -l app=pi-web
# deploy a changed Pod spec with enhaced logging:
kubectl apply -f pi/web/update/web-lo






  



