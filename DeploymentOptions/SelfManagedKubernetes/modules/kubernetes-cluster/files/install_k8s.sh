#!/bin/bash

render_kubeinit(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | grep -Po '(?<=src )(\S+)')

cat <<-EOF > /root/kubeadm-init-config.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $ADVERTISE_ADDR
  bindPort: ${kube_api_port}
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: $HOSTNAME
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
  certSANs:
    - $HOSTNAME
    - $ADVERTISE_ADDR
    %{~ if expose_kubeapi ~}
    - ${k8s_tls_san_public}
    %{~ endif ~}
    %{~ if expose_kubeapi_locally ~}
    - "localhost"
    %{~ endif ~}
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: ${k8s_version}
controlPlaneEndpoint: ${control_plane_url}:${kube_api_port}
networking:
  dnsDomain: ${k8s_dns_domain}
  podSubnet: ${k8s_pod_subnet}
  serviceSubnet: ${k8s_service_subnet}
scheduler: {}
etcd:
  local:
    dataDir: /var/lib/etcd
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
}

wait_lb() {
while [ true ]
do
  curl --output /dev/null --silent -k https://${control_plane_url}:${kube_api_port}
  if [[ "$?" -eq 0 ]]; then
    break
  fi
  sleep 5
  echo "wait for LB"
done
}

wait_for_ca_secret(){
  res_ca=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
  while [[ -z "$res_ca" || "$res_ca" == "${default_secret_placeholder}" ]]
  do
    echo "Waiting the ca hash ..."
    res_ca=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
    sleep 1
  done

  res_cert=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_cert_secret_name} | jq -r .SecretString)
  while [[ -z "$res_cert" || "$res_cert" == "${default_secret_placeholder}" ]]
  do
    echo "Waiting the ca hash ..."
    res_cert=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_cert_secret_name} | jq -r .SecretString)
    sleep 1
  done

  res_token=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString)
  while [[ -z "$res_token" || "$res_token" == "${default_secret_placeholder}" ]]
  do
    echo "Waiting the ca hash ..."
    res_token=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString)
    sleep 1
  done
}

wait_for_pods(){
  until kubectl get pods -A | grep 'Running'; do
    echo 'Waiting for k8s startup'
    sleep 5
  done
}

wait_for_masters(){
  until kubectl get nodes -o wide | grep 'control-plane'; do
    echo 'Waiting for k8s control-planes'
    sleep 5
  done
}

setup_env(){
  until [ -f /etc/kubernetes/admin.conf ]
  do
    sleep 5
  done
  echo "K8s initialized"
  export KUBECONFIG=/etc/kubernetes/admin.conf
}

render_kubejoin(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | grep -Po '(?<=src )(\S+)')
CA_HASH=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
KUBEADM_CERT=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_cert_secret_name} | jq -r .SecretString)
KUBEADM_TOKEN=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString)

cat <<-EOF > /root/kubeadm-join-master.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $KUBEADM_TOKEN
    apiServerEndpoint: ${control_plane_url}:${kube_api_port}
    caCertHashes: 
      - sha256:$CA_HASH
controlPlane:
  localAPIEndpoint:
    advertiseAddress: $ADVERTISE_ADDR
    bindPort: ${kube_api_port}
  certificateKey: $KUBEADM_CERT
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: $HOSTNAME
  taints: null
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
}

render_nginx_config(){
cat << 'EOF' > "$NGINX_RESOURCES_FILE"
---
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  ports:
  - appProtocol: http
    name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: ${extlb_listener_http_port}
  - appProtocol: https
    name: https
    port: 443
    protocol: TCP
    targetPort: https
    nodePort: ${extlb_listener_https_port}
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  type: NodePort
---
apiVersion: v1
data:
  allow-snippet-annotations: "true"
  enable-real-ip: "true"
  proxy-real-ip-cidr: "0.0.0.0/0"
  proxy-body-size: "20m"
  use-proxy-protocol: "true"
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: ${nginx_ingress_release}
  name: ingress-nginx-controller
  namespace: ingress-nginx
EOF
}

install_and_configure_nginx(){
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${nginx_ingress_release}/deploy/static/provider/baremetal/deploy.yaml
  NGINX_RESOURCES_FILE=/root/nginx-ingress-resources.yaml
  render_nginx_config
  kubectl apply -f $NGINX_RESOURCES_FILE
}

render_staging_issuer(){
STAGING_ISSUER_RESOURCE=$1
cat << 'EOF' > "$STAGING_ISSUER_RESOURCE"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: letsencrypt-staging
 namespace: cert-manager
spec:
 acme:
   # The ACME server URL
   server: https://acme-staging-v02.api.letsencrypt.org/directory
   # Email address used for ACME registration
   email: ${certmanager_email_address}
   # Name of a secret used to store the ACME account private key
   privateKeySecretRef:
     name: letsencrypt-staging
   # Enable the HTTP-01 challenge provider
   solvers:
   - http01:
       ingress:
         class:  nginx
EOF
}

render_prod_issuer(){
PROD_ISSUER_RESOURCE=$1
cat << 'EOF' > "$PROD_ISSUER_RESOURCE"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: ${certmanager_email_address}
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
}

install_and_configure_certmanager(){
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${certmanager_release}/cert-manager.yaml
  render_staging_issuer /root/staging_issuer.yaml
  render_prod_issuer /root/prod_issuer.yaml

  # Wait cert-manager to be ready
  until kubectl get pods -n cert-manager | grep 'Running'; do
    echo 'Waiting for cert-manager to be ready'
    sleep 15
  done

  kubectl create -f /root/prod_issuer.yaml
  kubectl create -f /root/staging_issuer.yaml
}

install_and_configure_csi_driver(){
  git clone https://github.com/kubernetes-sigs/aws-efs-csi-driver.git
  cd aws-efs-csi-driver/
  git checkout tags/${efs_csi_driver_release} -b kube_deploy_${efs_csi_driver_release}
  kubectl apply -k deploy/kubernetes/overlays/stable/

  # Uncomment this to mount the EFS share on the first k8s-server node
  # mkdir /efs
  # aws_region="$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)"
  # mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_filesystem_id}.efs.$aws_region.amazonaws.com:/ /efs
}

k8s_join(){
  kubeadm join --config /root/kubeadm-join-master.yaml
  mkdir ~/.kube
  cp /etc/kubernetes/admin.conf ~/.kube/config

  # Upload kubeconfig on AWS secret manager
  cat ~/.kube/config | sed 's/server: https:\/\/127.0.0.1:6443/server: https:\/\/${control_plane_url}:${kube_api_port}/' > /root/kube.conf
  aws secretsmanager update-secret --region ${region} --secret-id ${kubeconfig_secret_name} --secret-string file:///root/kube.conf
}

wait_for_secretsmanager(){
  res=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
  while [[ -z "$res" ]]
  do
    echo "Waiting the ca hash ..."
    res=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
    sleep 1
  done
}

generate_secrets(){
  wait_for_secretsmanager
  HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
  echo $HASH > /tmp/ca.txt

  TOKEN=$(kubeadm token create)
  echo $TOKEN > /tmp/kubeadm_token.txt

  CERT=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)
  echo $CERT > /tmp/kubeadm_cert.txt

  aws secretsmanager update-secret --region ${region} --secret-id ${kubeadm_ca_secret_name} --secret-string file:///tmp/ca.txt
  aws secretsmanager update-secret --region ${region} --secret-id ${kubeadm_cert_secret_name} --secret-string file:///tmp/kubeadm_cert.txt
  aws secretsmanager update-secret --region ${region} --secret-id ${kubeadm_token_secret_name} --secret-string file:///tmp/kubeadm_token.txt
}

k8s_init(){
  kubeadm init --config /root/kubeadm-init-config.yaml
  mkdir ~/.kube
  cp /etc/kubernetes/admin.conf ~/.kube/config
}

setup_cni(){
  until kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml; do
    echo "Trying to install CNI flannel"
  done
}

first_instance=$(aws ec2 describe-instances --region ${region} --filters Name=tag:k8s-instance-type,Values=k8s-server Name=instance-state-name,Values=running --query 'sort_by(Reservations[].Instances[], &LaunchTime)[:-1].[InstanceId]' --output text | head -n1)
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

if [[ "$first_instance" == "$instance_id" ]]; then
  render_kubeinit
  k8s_init
  setup_env
  wait_for_pods
  setup_cni
  generate_secrets
  echo "Wait 180 seconds for control-planes to join"
  sleep 180
  wait_for_masters
  %{ if install_nginx_ingress }
  install_and_configure_nginx
  %{ endif }
  %{ if install_certmanager }
  install_and_configure_certmanager
  %{ endif }
  %{ if efs_persistent_storage }
  install_and_configure_csi_driver
  %{ endif }
  %{ if install_node_termination_handler }
  #Install node termination handler
  echo 'Install node termination handler'
  kubectl apply -f https://github.com/aws/aws-node-termination-handler/releases/download/${node_termination_handler_release}/all-resources.yaml
  %{ endif }
else
  wait_for_ca_secret
  render_kubejoin
  wait_lb
  k8s_join
fi