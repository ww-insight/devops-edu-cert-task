FROM ubuntu
RUN apt update
RUN apt install default-jdk -y
RUN apt install tomcat9 -y
RUN apt install maven -y
RUN apt install git -y
RUN git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git
RUN mvn package -f boxfuse-sample-java-war-hello/
RUN cp boxfuse-sample-java-war-hello/target/hello-1.0.war /var/lib/tomcat9/webapps
EXPOSE 8080
ENV CATALINA_BASE /var/lib/tomcat9/
ENV CATALINA_HOME /usr/share/tomcat9
CMD $CATALINA_HOME/bin/catalina.sh run