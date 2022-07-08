FROM jenkins/jenkins:lts-jdk11
COPY terraform /bin/terraform
COPY terraformrc /root/.terraformrc
RUN apt update
RUN apt install ansible -y