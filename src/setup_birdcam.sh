#!/bin/bash

AWS_SSM_SERVICE_ROLE="SSMServerRole"
#change region if necessary
AWS_REGION="us-east-2"

#install picam and pyenv dependencies
sudo apt-get update && sudo apt-get install -y rpicam-apps make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl jq

curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo ln -s /usr/local/bin/aws /usr/bin/aws 
sudo ln -s /usr/local/bin/aws_completer /usr/libexec/aws_completer

sudo apt --fix-broken install

echo "Now pull down credentials file and create a role as specified in the github page. When that is done, type in the name of the role you created here and press enter"
read AWS_SSM_SERVICE_ROLE

aws ssm create-activation \
  --default-instance-name BirdCam1 \
  --description "Activation for bird cam" \
  --iam-role "$AWS_SSM_SERVICE_ROLE" \
  --region "$AWS_REGION" > activation_info.json

ACTIVATION_ID="$(jq '.ActivationId' activation_info.json)"
ACTIVATION_CODE="$(jq '.ActivationCode' activation_info.json)"
  
mkdir /tmp/ssm
curl "https://amazon-ssm-""$AWS_REGION"".s3.""$AWS_REGION"".amazonaws.com/latest/debian_arm/ssm-setup-cli" -o /tmp/ssm/ssm-setup-cli
sudo chmod +x /tmp/ssm/ssm-setup-cli
sudo /tmp/ssm/ssm-setup-cli -register -activation-code "$ACTIVATION_CODE" -activation-id "$ACTIVATION_ID" -region "$AWS_REGION"


#setup pyenv
curl https://pyenv.run | bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
echo 'eval "$(pyenv init -)"' >> ~/.profile
exec "$SHELL"
pyenv install -v 3.9.19
pyenv global 3.9.19
python -V

#install coral dependencies
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install -y libedgetpu1-std python3-pycoral
pip install --upgrade pip
pip install https://github.com/google-coral/pycoral/releases/download/v2.0.0/tflite_runtime-2.5.0.post1-cp39-cp39-linux_aarch64.whl#sha256=9839c3acb506b5003a9bd3860329a8ae20e675efbae14dbea02659b0054f42c6
python3 -m pip install --extra-index-url https://google-coral.github.io/py-repo/ pycoral~=2.0

mkdir coral && cd coral || echo "error making and entering directory" && exit 1
git clone https://github.com/google-coral/pycoral.git
cd pycoral || exit
bash examples/install_requirements.sh classify_image.py

cd ~ || echo "error making and entering directory" && exit 1
git clone https://github.com/LetsOKdo/pi-coral-ai-birdcam.git
cd ~/pi-coral-ai-birdcam || echo "error making and entering directory" && exit 1
bash birdcam/install_requirements.sh

cd ~ || exit 1

pip install boto3

#use git clone instead
git clone https://github.com/shivapal/ai-birdcam.git

mkdir ~/BirdcamCustom
cd ~/BirdcamCustom || exit 1

mv -R ~/ai-birdcam/src/* .
mv ~/ai-birdcam/system/wayfire.ini ~/.config/

#docker and kubernetes setup
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings -y
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo groupadd docker
sudo usermod -aG docker birdcam
newgrp docker

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
sudo install minikube-linux-arm64 /usr/local/bin/minikube -y && rm minikube-linux-arm64

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
sudo apt-get update
sudo apt-get install -y kubectl
su birdcam -c "minikube start"
su birdcam -c "minikube addons enable metrics-server"
su birdcam -c "kubectl create deployment hello-node --image=registry.k8s.io/e2e-test-images/agnhost:2.39 -- /agnhost netexec --http-port=8080"
su birdcam -c "kubectl expose deployment hello-node --type=LoadBalancer --port=8080"

#potential cleanup
#kubectl delete service hello-node
#kubectl delete deployment hello-node
#minikube stop

