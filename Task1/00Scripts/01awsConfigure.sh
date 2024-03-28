#!/bin/bash
mkdir -p ~/.aws
cat << EOF > ~/.aws/credentials
[default]
aws_access_key_id = AKIARCLE3KSJJLKICG4S
aws_secret_access_key = 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
EOF
cat << EOF > ~/.aws/config
[default]
region = ap-northeast-2
EOF
echo "----------------------------------------------"
aws configure
echo "----------------------------------------------"
