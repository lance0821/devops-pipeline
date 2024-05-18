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
              withSonarQubeEnv(credentialsId: 'jenkins-sonarqube-token') {
                sh "mvn sonar:sonar"
            }
        }
    }
}
