#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 
echo 'Skill53##' | passwd --stdin ec2-user 
systemctl enable --now sshd 
systemctl restart sshd
echo "------------------------------"
cat /etc/ssh/sshd_config | grep "PasswordAuthentication yes"
echo "------------------------------"
