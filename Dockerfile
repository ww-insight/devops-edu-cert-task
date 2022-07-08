FROM jenkins/jenkins:lts-jdk11
COPY terraform /bin/terraform
COPY terraform.rc /root/.terraform.rc
RUN apt update
RUN apt install ansible -y