To get this operator to work

Followed the outline as described here:

https://sdk.operatorframework.io/docs/building-operators/ansible/tutorial/

Exact steps

operator-sdk init --plugins=ansible --domain pdteam.apple.com
operator-sdk create api --group cache --version v1alpha1 --kind Memcached --generate-role

Created custom ansible_cfg file to configure ansible in the container
```
nelson_huang@pdt-rno-np-rke01m:~/ansible-k8s-operator/memcached-operator_1.12$ more ansible_cfg

[defaults]
roles_path = /opt/ansible/roles
#library = /usr/share/ansible/openshift
#library = /usr/local/lib/python3.8/site-packages
interpreter_python=/usr/bin/python3
COLLECTIONS_PATH=./.ansible/collections
```


Updated Dockerfile
```
FROM quay.io/operator-framework/ansible-operator:v1.6.1

# export proxy
# Need this in order for the container to function
ENV https_proxy "http://pbpr-epic-squid.apple.com:3128"
ENV http_proxy  "http://pbpr-epic-squid.apple.com:3128"

# configure ansible
copy ansible_cfg ${HOME}/ansible.cfg

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
```


make docker-build IMG=docker.apple.com/nelson_huang/memcached-operator:latest
docker push docker.apple.com/nelson_huang/memcached-operator:latest


```
# To deploy create an instance of the CRD in a designated namespace
kubectl apply -f config/samples/cache_v1alpha1_memcached.yaml

nelson_huang@pdt-rno-np-rke01m:~/ansible-k8s-operator/memcached-operator_1.12$ kubectl get Memcached
NAME               AGE
memcached-sample   38m

nelson_huang@pdt-rno-np-rke01m:~/ansible-k8s-operator/memcached-operator_1.12$ kubectl get pods
NAME                                         READY   STATUS    RESTARTS   AGE
memcached-sample-memcached-54946946b-4wnj5   1/1     Running   0          39m
memcached-sample-memcached-54946946b-d6b26   1/1     Running   0          39m
```

To deploy in a specific namespace
```
kubectl apply -f config/samples/cache_v1alpha1_memcached.yaml -n pdt-devops-pr2

nelson_huang@pdt-rno-np-rke01m:~/ansible-k8s-operator/memcached-operator$ kubectl get pods -n pdt-devops-pr2
NAME                                         READY   STATUS    RESTARTS   AGE
memcached-sample-memcached-54946946b-hlck7   1/1     Running   0          3m41s
memcached-sample-memcached-54946946b-l75dj   1/1     Running   0          3m41s
memcached-sample-memcached-54946946b-x58xc   1/1     Running   0          3m41s
pdt-devops-pr2-cache-redis-0                 1/1     Running   0          30h
pdt-devops-pr2-drupalapp-0                   4/4     Running   0          4d
pdt-devops-pr2-mysql-5c5bd97b84-gl76d        1/1     Running   0          37h

```

