#!/bin/bash

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/bin/kubectl

vagrant ssh master1 -c "cp -r /home/vagrant/.kube /vagrant/.kube"
rm -rf $HOME/.kube && mkdir -p $HOME/.kube
mv .kube $HOME/
