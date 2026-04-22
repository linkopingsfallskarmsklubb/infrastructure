FROM docker.io/tomcat:11.0-jre21

ARG SKYWINONE_VERSION=26.0.0

RUN curl -LJO --output-dir /usr/local/tomcat/webapps https://www.skywinner.se/skywin/_files/skywinone/${SKYWINONE_VERSION}/skywinone.war

EXPOSE 8080

