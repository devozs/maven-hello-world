ARG VERSION=1.0.0

# Build the application with version
FROM maven:3.8.4-openjdk-17 as builder
ARG VERSION

COPY src /usr/src/app/src
COPY pom.xml /usr/src/app

WORKDIR /usr/src/app
RUN mvn versions:set -DnewVersion=${VERSION}
RUN mvn clean package

# Create the App image
FROM openjdk:17-slim
ARG VERSION
ENV APP_NAME_VERSION=myapp-${VERSION}
ENV NAME=Anonymous

RUN groupadd -r javauser && useradd -r -g javauser javauser

USER javauser:javauser
COPY --from=builder /usr/src/app/target/${APP_NAME_VERSION}.jar /usr/app/${APP_NAME_VERSION}.jar
WORKDIR /usr/app

ENTRYPOINT java -jar /usr/app/${APP_NAME_VERSION}.jar
CMD ["${NAME}"]
