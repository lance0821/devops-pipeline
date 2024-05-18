pipeline {
    agent {
        kubernetes {
            inheritFrom 'jnlp-slave'
            defaultContainer 'jnlp'
        }
    }
    tools {
        jdk 'Java17'
        maven 'Maven3'
    }
    environment {
        APP_NAME = 'devops-pipeline'
        RELEASE = '1.0.0'
        DOCKER_USER = 'lance0821'
        DOCKER_PASS = credentials('docker-hub-credentials')
        IMAGE_NAME = "${DOCKER_USER}/${APP_NAME}:${RELEASE}"
        IMAGE_TAG = "${DOCKER_USER}/${APP_NAME}:${RELEASE}-${BUILD_NUMBER}"
    }
    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout Code From Github') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/lance0821/devops-pipeline.git'
            }
        }
        
        stage('Build Application') {
            steps {
                sh "mvn clean package"
            }
        }
        stage('Test Application') {
            steps {
                sh "mvn test"
            }
        }
        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    withCredentials([string(credentialsId: 'jenkins-sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh "mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN -Dsonar.projectVersion=${BUILD_NUMBER}"
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: true
            }
        }
        stage('Build & Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                        def customImage = docker.build("${IMAGE_NAME}")
                        customImage.push()
                        customImage.push("${RELEASE}-${BUILD_NUMBER}")
                        customImage.push("latest")
                    }
                }
            }
        }
    }
}
