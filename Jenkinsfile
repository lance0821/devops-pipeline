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
  - name: podman
    image: quay.io/podman/stable
    command:
      - cat
    tty: true
    securityContext:
      privileged: true
    volumeMounts:
      - name: podman-sock
        mountPath: /run/podman/podman.sock
      - name: podman-storage
        mountPath: /var/lib/containers/storage
  volumes:
  - name: workspace-volume
    emptyDir: {}
  - name: podman-sock
    hostPath:
      path: /run/podman/podman.sock
      type: Socket
  - name: podman-storage
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
                        sh """
                        mvn sonar:sonar \
                        -Dsonar.login=$SONAR_TOKEN \
                        -Dsonar.projectVersion=${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: true
            }
        }
        stage('Verify Podman') {
            steps {
                container('podman') {
                    sh 'podman --version'
                    sh 'podman run hello-world'
                }
            }
        }
        stage('Build & Push Podman Image') {
            steps {
                script {
                    withEnv(["DOCKER_HOST=unix:///run/podman/podman.sock"]) {
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
