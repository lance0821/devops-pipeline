pipeline {
    agent {
        kubernetes {
                        yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins/label: jnlp-slave
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
    tty: true
    volumeMounts:
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  - name: docker
    image: docker:26.1.3-dind
    securityContext:
      privileged: true
    env:
      - name: DOCKER_TLS_CERTDIR
        value: ""
    volumeMounts:
      - name: docker-sock
        mountPath: /var/run/docker.sock
      - name: docker-storage
        mountPath: /var/lib/docker
  volumes:
  - name: workspace-volume
    emptyDir: {}
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
  - name: docker-storage
    emptyDir: {}
"""
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
                waitForQualityGate abortPipeline: false
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
