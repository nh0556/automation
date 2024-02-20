# Setting up

* kubectl apply -f etcd-sts.yaml -n nelson-huang2

Testing etcdctl version
```
nelson_huang@pdt-rno-np-rke01m:~/dev/hacking/k8s/etcd$ k exec -it etcd-0 -n nelson-huang2 -- /bin/sh -c 'ETCDCTL_API=3 etcdctl version'

etcdctl version: 3.3.8
API version: 3.3

```


etcdctl member list
```
nelson_huang@pdt-rno-np-rke01m:~/dev/hacking/k8s/etcd$ k exec -it etcd-0 -n nelson-huang2 -- /bin/sh -c 'ETCDCTL_API=3 etcdctl member list'


2e80f96756a54ca9, started, etcd-0, http://etcd-0.etcd:2380, http://etcd-0.etcd:2379
7fd61f3f79d97779, started, etcd-1, http://etcd-1.etcd:2380, http://etcd-1.etcd:2379
b429c86e3cd4e077, started, etcd-2, http://etcd-2.etcd:2380, http://etcd-2.etcd:2379
```

cluster-health
```
nelson_huang@pdt-rno-np-rke01m:~/dev/hacking/k8s/etcd$ k exec -it etcd-0 -n nelson-huang2 -- etcdctl cluster-health


member 2e80f96756a54ca9 is healthy: got healthy result from http://etcd-0.etcd:2379
member 7fd61f3f79d97779 is healthy: got healthy result from http://etcd-1.etcd:2379
member b429c86e3cd4e077 is healthy: got healthy result from http://etcd-2.etcd:2379
cluster is healthy
```

Inserting a key
```
nelson_huang@pdt-rno-np-rke01m:~/dev/hacking/k8s/etcd$ k exec -it etcd-0 -n nelson-huang2 -- /bin/sh -c 'ETCDCTL_API=3 etcdctl put message hello-world!'

OK
```

Get a key (value)
```
nelson_huang@pdt-rno-np-rke01m:~/dev/hacking/k8s/etcd$ k exec -it etcd-0 -n nelson-huang2 -- /bin/sh -c 'ETCDCTL_API=3 etcdctl get message'

message
hello-world!
```


