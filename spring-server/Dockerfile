
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
ARG GRADUATION=false
RUN if [ "$GRADUATION" = "true" ]; then mkdir -p src/main/resources/properties && cp graduation-properties/*.properties src/main/resources/properties/; fi
RUN mvn clean package -q -DskipTests


FROM tomcat:9.0-jdk17
RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
