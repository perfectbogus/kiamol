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









