FROM jenkins/jenkins:lts-jdk11
USER root
COPY terraform /bin/terraform
RUN chmod +x /bin/terraform
COPY terraformrc /root/.terraformrc
RUN apt update
RUN apt install ansible -y