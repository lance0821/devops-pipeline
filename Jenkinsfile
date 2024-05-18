pipeline {
    agent {
        kubernetes {
            inheritFrom 'jnlp-slave'
            defaultContainer 'jnlp'
        }
    }
    tools (
      jdk 'Java17'
      maven 'Maven3'
    )
    stages {
        stage('Cleanup Workspace') {
            steps {
                echo "========== Executing Cleaning Workspace =========="
                cleanWs()
            }
        }
        stage('Checkout Code From Github') {
            steps {
                echo "========== Checking out code =========="
                git branch: 'main', credentialId: 'github-credentials', url: 'https://github.com/lance0821/devops-pipeline'
            }
        }
    }
}