// Requires the "SSH Agent" Jenkins plugin for the sshagent() step below.
pipeline {
    agent any

    // POC default: poll instead of a GitHub webhook, so we don't need to
    // open inbound access or run a relay client. Checks every 5 min - see
    // docs/WEBHOOK-SETUP.md if you want to switch to instant triggering later.
    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        IRIS_HOST      = credentials('iris-host')       // e.g. 10.0.2.x (private IP)
        IRIS_NAMESPACE = 'USER'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test routines') {
            steps {
                sh 'chmod +x build/test-routines.sh'
                sh './build/test-routines.sh'
            }
        }

        stage('Deploy routines to VistA/IRIS') {
            steps {
                // 'iris-ssh-key' is the same EC2 key pair used for all POC
                // instances, added to Jenkins as an "SSH Username with
                // private key" credential - see docs/GETTING-STARTED.md
                sshagent(credentials: ['iris-ssh-key']) {
                    sh 'chmod +x build/load-routines.sh'
                    sh './build/load-routines.sh'
                }
            }
        }

        stage('Smoke test') {
            steps {
                sshagent(credentials: ['iris-ssh-key']) {
                    sh 'chmod +x build/smoke-test.sh'
                    sh './build/smoke-test.sh'
                }
            }
        }
    }

    post {
        success {
            echo 'Deployed to VistA/IRIS successfully.'
        }
        failure {
            echo 'Deploy failed - check the load-routines.sh output above.'
        }
    }
}
