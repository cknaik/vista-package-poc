pipeline {
    agent any

    // POC default: poll instead of a GitHub webhook, so we don't need to
    // open inbound access or run a relay client. Checks every 5 min - see
    // docs/WEBHOOK-SETUP.md if you want to switch to instant triggering later.
    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        IRIS_HOST      = credentials('iris-host')       // e.g. 10.0.2.x
        IRIS_NAMESPACE = 'USER'
        IRIS_USER      = credentials('iris-user')
        IRIS_PASSWORD  = credentials('iris-password')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy routines to VistA/IRIS') {
            steps {
                sh 'chmod +x build/load-routines.sh'
                sh './build/load-routines.sh'
            }
        }

        // Optional smoke test stage - uncomment and adapt once you have a
        // simple validation routine to call after load.
        // stage('Smoke test') {
        //     steps {
        //         sh './build/smoke-test.sh'
        //     }
        // }
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
