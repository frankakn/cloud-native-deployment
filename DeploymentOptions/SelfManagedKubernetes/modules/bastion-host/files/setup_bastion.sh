#!/bin/bash

groupadd ${bastion_group}
useradd -d /home/${bastion_user} -r -g ${bastion_group} ${bastion_user}
mkdir -p /home/${bastion_user}/.ssh
touch /home/${bastion_user}/.ssh/authorized_keys
%{ for ssh_key in ssh_keys }
echo "${ssh_key}" >> /home/${bastion_user}/.ssh/authorized_keys
%{ endfor }
chown -R ${bastion_group}:${bastion_user} /home/${bastion_user}/
chmod 400 /home/${bastion_user}/.ssh/authorized_keys

cat <<EOD >> /etc/ssh/sshd_config 
Match Group ${bastion_group}
   AllowAgentForwarding yes
   AllowTcpForwarding yes
   X11Forwarding yes
   PermitTunnel yes
   GatewayPorts yes
   ForceCommand echo 'This account can only be used for ProxyJump (ssh -J)'
EOD

systemctl restart sshd.service