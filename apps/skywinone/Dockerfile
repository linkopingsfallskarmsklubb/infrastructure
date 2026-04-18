FROM docker.io/tomcat:9.0-jre11

ARG SKYWINONE_VERSION=25.0.3

RUN curl -LJO --output-dir /usr/local/tomcat/webapps https://www.skywinner.se/skywin/_files/skywinone/${SKYWINONE_VERSION}/skywinone.war

EXPOSE 8080

