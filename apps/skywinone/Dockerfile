FROM docker.io/tomcat:10.1.56-jre21

ARG SKYWINONE_VERSION=26.0.4

RUN curl --fail --location --show-error --output /usr/local/tomcat/webapps/skywinone.war \
  https://www.skywinner.se/skywin/_files/skywinone/${SKYWINONE_VERSION}/skywinone.war && \
  [ -s /usr/local/tomcat/webapps/skywinone.war ] && \
  head -c 2 /usr/local/tomcat/webapps/skywinone.war | grep -q 'PK' || \
  { echo "ERROR: Download failed, file is empty, or not a valid WAR/ZIP file"; exit 1; }

EXPOSE 8080

