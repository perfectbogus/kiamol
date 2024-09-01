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









