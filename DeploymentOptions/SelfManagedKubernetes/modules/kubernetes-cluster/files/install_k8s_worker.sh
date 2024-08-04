#!/bin/bash

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
  res=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
  while [[ -z "$res" || "$res" == "${default_secret_placeholder}" ]]
  do
    echo "Waiting the ca hash ..."
    res=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
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

render_kubejoin(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | grep -Po '(?<=src )(\S+)')
CA_HASH=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString)
KUBEADM_TOKEN=$(aws secretsmanager get-secret-value --region ${region} --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString)

cat <<-EOF > /root/kubeadm-join-worker.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $KUBEADM_TOKEN
    apiServerEndpoint: ${control_plane_url}:${kube_api_port}
    caCertHashes: 
      - sha256:$CA_HASH
localAPIEndpoint:
  advertiseAddress: $ADVERTISE_ADDR
  bindPort: ${kube_api_port}
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

k8s_join(){
  kubeadm join --config /root/kubeadm-join-worker.yaml
}

wait_lb

wait_for_ca_secret
render_kubejoin
k8s_join