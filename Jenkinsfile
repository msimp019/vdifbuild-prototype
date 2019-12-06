
def HS_List = ['localhost:56778','localhost:56778']
def HS_BuildTargetFolder = '/opt/VABUILD/'
def HS_BuildInstance = 'HS01'
def HS_BuildNamespace = 'VABUILD'
def HS_SourceBranch = 'develop'
def HS_IntBranch = 'int/develop'


pipeline {
    agent any
	environment {
        HS_CREDENTIALS = credentials('HealthShare-Credentials')
    }
	
    stages {
        stage('Prepare Build Environment') {
            steps {
                //sh "rm -rf ${HS_BuildTargetFolder}"
				//sh "mkdir ${HS_BuildTargetFolder}"
                sh 'cd "${WORKSPACE}"'
                // Allow the jenkins user the ability to execute the shell files found in the build folder
                sh "chmod a+x build/*.sh"
				sh "./buildInstallerNamespace ${HS_BuildInstance} ${WORKSPACE} '%SYS' ${HS_BuildTargetFolder} ${HS_BuildNamespace}"
			}
        }
        stage('Build') {
            steps {
                sh 'echo "Call Build method on build instance"'
			}
        }
		stage('Test') {
            steps {
                sh 'echo "No tests configured"'
            }
        }
		stage('Deploy') {
            steps {
                deploy_loop(${HS_List})
            }
        }
    }
	post {
		always {
			sh 'echo "maybe post is where to call test"'
		}

    }
	
}

@NonCPS
def deploy_loop(HS_List) {
	HS_List.each { item ->
		sh 'echo "deploy to: " ${item}'
	}

}
