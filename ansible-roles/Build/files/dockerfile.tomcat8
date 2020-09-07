FROM openjdk:8-jre-alpine
WORKDIR /usr/local
RUN apk add --no-cache bash curl &&\
    curl -LO http://mirrors.standaloneinstaller.com/apache/tomcat/tomcat-8/v8.5.56/bin/apache-tomcat-8.5.56.tar.gz &&\
    tar xvzf apache-tomcat-8.5.56.tar.gz &&\
    mv apache-tomcat-8.5.56 tomcat &&\
    rm -f apache-tomcat-8.5.56.tar.gz &&\
    rm -Rf tomcat/webapps/*
ADD ./ROOT.war tomcat/webapps
#ENV CATALINA_HOME /usr/local/tomcat
CMD ["tomcat/bin/catalina.sh","run"]