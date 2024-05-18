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
        IMAGE_NAME = "docker.io/${DOCKER_USER}/${APP_NAME}:${RELEASE}"
        IMAGE_TAG = "docker.io/${DOCKER_USER}/${APP_NAME}:${RELEASE}-${BUILD_NUMBER}"
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
        stage('Build & Push Docker Image') {
            steps {
                container('podman') {
                    script {
                        withCredentials([string(credentialsId: 'docker-hub-pass', variable: 'DOCKER_PASS')]) {
                            sh """
                            podman login -u ${DOCKER_USER} -p ${DOCKER_PASS} docker.io
                            podman build -t ${IMAGE_NAME} .
                            podman tag ${IMAGE_NAME} ${IMAGE_TAG}
                            podman tag ${IMAGE_NAME} docker.io/${DOCKER_USER}/${APP_NAME}:latest
                            podman push ${IMAGE_NAME}
                            podman push ${IMAGE_TAG}
                            podman push docker.io/${DOCKER_USER}/${APP_NAME}:latest
                            """
                        }
                    }
                }
            }
        }
        stage('Trigger CD Pipeline') {
            steps {
                container('podman') {
                    withCredentials([string(credentialsId: 'JENKINS_API_TOKEN', variable: 'API_TOKEN')]) {
                        script {
                            def crumb = sh(script: """
                                curl -u admin:${API_TOKEN} \
                                'https://jenkins.lancelewandowski.com/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' \
                                """, returnStdout: true).trim()
                            sh """
                            curl -v -k --user admin:${API_TOKEN} \
                            -H "${crumb}" \
                            -X POST -H 'cache-control: no-cache' \
                            -H 'content-type: application/x-www-form-urlencoded' \
                            --data-urlencode 'IMAGE_TAG=${IMAGE_TAG}' \
                            'https://jenkins.lancelewandowski.com/job/gitops-pipeline/buildWithParameters?token=gitops-token'
                            """
                        }
                    }
                }
            }
        }
    }
}
