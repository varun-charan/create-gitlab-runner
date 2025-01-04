#!/bin/bash
 
echo "######################   START OF GitLab Runner Provisioner   ######################"
echo
 
set -e

source /home/cloud-user/configuration.env
 
export http_proxy=http://www-some-proxy.com:80
export HTTPS_PROXY=http://www-some-proxy.com:80
export https_proxy=http://www-some-proxy.com:80
export no_proxy=localhost,127.0.0.1
export HTTP_PROXY=http://www-some-proxy.com:80
 
if [ `id -u` -ne 0 ]; then
   echo "ERROR: This script can be executed only as sudo, Exiting...."
   exit 1
fi
 
yum install -y git wget
if [[ $? != 0 ]]; then
        echo "Git could not be installed properly. Please check. Exiting...."
        exit 1
fi
 
 
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
if [[ $? != 0 ]]; then
        echo "Git could not be installed properly. Please check. Exiting...."
        exit 1
fi
 
curl --connect-timeout 10 -O https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_linux-x64_bin.tar.gz
if [[ $? != 0 ]]; then
        echo "OpenJDK TAR file could not be downloaded. Please check. Exiting...."
        exit 1
fi

tar -zxvf openjdk-11.0.1_linux-x64_bin.tar.gz
rm -rf /usr/local/jdk-11.0.1
mv jdk-11.0.1 /usr/local/jdk-11.0.1
export JAVA_HOME=/usr/local/jdk-11.0.1
export JRE_HOME=/usr/local/jdk-11.0.1
 
 
# Install Gitlab Runner
rm -rf script.rpm.sh*
wget https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh
if [[ $? != 0 ]]; then
        echo "Gitlab runner installer script could not be downloaded properly. Please check. Exiting...."
        exit 1
fi
 
bash script.rpm.sh
 
yum-config-manager --enable ol7_addons
yum install -y docker-engine gitlab-runner
 
mkdir -p /etc/systemd/system/docker.service.d/
 
cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://www-some-proxy.com:80" "HTTPS_PROXY=http://www-some-proxy.com:80" "NO_PROXY=localhost,127.0.0.1,10.75.214.29,master,10.75.214.40,slave1,10.75.214.23,slave2,10.244.0.0/16,10.96.0.0/12,${DOCKER_REGISTRY_NAME}"
EOF
 
systemctl daemon-reload && systemctl restart docker
if [[ $? != 0 ]]; then
        echo "Docker service could not be restarted. Please check. Exiting...."
        exit 1
fi
 
# Register this Gitlab Runner VM with your GitLab Server
gitlab-runner register << EOF
https://gitlab.us.com/
${GITLAB_RUNNER_TOKEN}
${GITLAB_RUNNER_NAME}
docker
coreos/apache
EOF
 
# let gitlab-runner able to run docker command
usermod -aG root gitlab-runner
echo 'gitlab-runner ALL=(ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo

chmod 666 /etc/gitlab-runner/config.toml
sed -i -e 's|concurrent = 1|concurrent = 3|g' /etc/gitlab-runner/config.toml
sed -i '12i\ \ environment = ["http_proxy=http://www-some-proxy.com:80", "https_proxy=http://www-some-proxy.com:80", "HTTPS_PROXY=http://www-some-proxy.com:80", "no_proxy=localhost,127.0.0.1", "HTTP_PROXY=http://www-some-proxy.com:80"]' /etc/gitlab-runner/config.toml
sed -i '13i\ \ pre_clone_script = "git config --global http.proxy $HTTP_PROXY; git config --global https.proxy $HTTPS_PROXY"' /etc/gitlab-runner/config.toml
sed -i -e 's|volumes = .*|volumes = ["/var/run/docker.sock:/var/run/docker.sock","/root/.ssh:/root/.ssh","/root/src:/root/src","/cache"]|g' /etc/gitlab-runner/config.toml
chmod 600 /etc/gitlab-runner/config.toml
 
# Run gitlab-runner
gitlab-runner run &
 
echo
echo "GitLab Runner (${GITLAB_RUNNER_NAME}) is registered and started successfully!!!"
 
echo
echo "######################   END OF GitLab Runner Provisioner   ######################"
