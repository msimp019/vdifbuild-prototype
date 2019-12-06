pipeline {
    agent any
	environment {
        HS_CREDENTIALS     = credentials('HealthShare-Credentials')
    }
    stages {
        stage('Build') {
            steps {
                sh 'echo "Begin Build"'
				sh 'ccontrol list'
            }
        }
		stage('Test') {
            steps {
                sh 'echo "run tests after deploy"'
            }
        }
		stage('Deploy') {
            steps {
                sh 'echo "call the deploy script either once and let it target all machines, or iteratively here to complete the deployment"'
            }
        }
    }
	post {
	always {
		sh 'echo "maybe post is where to call test"'
	}

    }
}