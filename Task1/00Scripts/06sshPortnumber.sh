#!/bin/bash
sudo sed -i 's/#Port 22/Port 2024/g' /etc/ssh/sshd_config 
systemctl enable --now sshd 
systemctl restart sshd
echo "----------"
cat /etc/ssh/sshd_config | grep "Port 2024"
echo "----------"
