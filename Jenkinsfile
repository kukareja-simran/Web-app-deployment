pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/kukareja-simran/Web-app-deployment.git'
      }
    }
    stage('Deploy') {
      environment {
        SSH_KEY = 'ssh-key'
        EC2_USER = 'ubuntu'
        EC2_HOST = 'ec2-3-6-39-247.ap-south-1.compute.amazonaws.com'
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
      }

      steps {
        sshagent(['ssh-key']) {
          sh "ssh -o StrictHostKeyChecking=no -l ${EC2_USER} ${EC2_HOST} 'cd /docker-compose-files && sudo docker-compose -f ${DOCKER_COMPOSE_FILE} up -d'"
        }
      }
    }
  }
}
