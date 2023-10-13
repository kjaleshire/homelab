# Kubernetes Manifests

## Bootstrap a new cluster

On the host, ensure the metrics server & Kubernetes API server will be available:

```fish
sudo ufw allow from 10.42.0.0/16 to any port 10250 comment "Metrics server"
sudo ufw allow from 10.42.0.0/16 to 10.43.0.1 port 443 comment "Kubernetes API server"
```

Install Cilium:

```fish
# IP or domain of the master node
set K8S_SERVICE_HOST 10.44.1.254
helm upgrade --install cilium cilium/cilium --version 1.14.0 --namespace kube-system --insecure-skip-tls-verify --set=ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" --set=kubeProxyReplacement=true --set=k8sServiceHost=$K8S_SERVICE_HOST --set=k8sServicePort=6443 --set=bgpControlPlane.enabled=true --wait
```

Bootstrap the external-secrets vault token secret following the instructions in [`infrastructure/secrets/README.md`](infrastructure/secrets/README.md).

Set a GitHub token:

```fish
# Github token with repo: privileges or fine-grained token with read/write access to admin & code for provisioning repo. Prefix command with space to keep out of shell history.
 set -xg GITHUB_TOKEN ghp_fkjdlskjfkdsuqierouwiroewvmcvmcvcxxc
```

Bootstrap flux with GitHub:

```shell
flux bootstrap github --components-extra=image-reflector-controller,image-automation-controller --owner=kjaleshire --repository=provisioning --path=kubernetes/clusters/outland --branch=master --personal=true --read-write-key=true
```

Don't forget to [enable hardware transcoding in Jellyfin](https://web.archive.org/web/20220324183626/https://www.careyscloud.ie/intel_gpu_plugin) under Playback, "Video Acceleration API (VAAPI).

Enable hardware decoding for all codecs except AV1. Support for AV1 decoding [doesn't exist in 9th-gen Intel Core](https://www.intel.com/content/www/us/en/docs/onevpl/developer-reference-media-intel-hardware/1-0/features-and-formats.html#DECODE-9TH); AV1 support is in 11th-gen Intel Core (Tiger Lake).

## Troubleshooting

If you ever run into a pod having a message "too many open files" and perhaps trying to watch an object, run this on the node:

```shell
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```

And to make the sysctl changes permanent, add these lines to `/etc/sysctl.conf`:

```shell
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```

[More info](https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files)

If you ever need to reset the `etcd` membership of k3s, for example your IP address changed and you got `Failed to test data store connection: this server is a not a member of the etcd cluster.`, run:

```shell
sudo k3s server --cluster-reset
```

To get a list of all resources (including custom types) within a namespace:

```shell
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -namespace $NAMESPACE
```

## Add a debug shell to a pod

[Netshoot](https://github.com/nicolaka/netshoot) is a well-known network troubleshooting image that can be useful. You can edit & apply `netshoot.yaml` to spin up a standalone pod or you can attach an ephemeral container to an existing pod:

```fish
set NAMESPACE default
set POD_NAME xyz-pod-12345-abcd
kubectl debug -n $NAMESPACE $POD_NAME -it --image=nicolaka/netshoot
```
