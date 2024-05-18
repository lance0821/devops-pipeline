# Stage 1: Build stage
FROM docker.io/library/maven:3.9.0-eclipse-temurin-17 as build
WORKDIR /app
COPY . .
RUN mvn clean install

# Stage 2: Runtime stage
FROM docker.io/library/eclipse-temurin:17.0.6_10-jdk as runtime
WORKDIR /app
COPY --from=build /app/target/demoapp.jar /app
EXPOSE 8080
CMD ["java", "-jar", "demoapp.jar"]
