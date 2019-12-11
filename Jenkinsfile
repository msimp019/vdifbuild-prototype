
def HS_List = ['localhost:56778','localhost:56778']
def HS_BuildTargetFolder = '/opt/VABUILD/'
def HS_BuildInstance = 'HS01'
def HS_BuildNamespace = 'VABUILD'
def Git_SourceBranch = 'develop'
def Git_IntBranch = 'int/develop'
def Git_RepoURL = 'github.com/msimp019/vdif-prototype.git'
date = new Date()
def dateTimeStamp = date.format("yyyyMMddHHmmss")

pipeline {
    agent any
	environment {
        HS_CREDENTIALS = credentials('HealthShare-Credentials')
		Git_CREDENTIALS = credentials('Git-CREDENTIALS')
		HS_DeployFileName = "$HS_BuildTargetFolder" + "DeployPackage_" + "${Git_IntBranch.replace('/','')}" + "_" + "$dateTimeStamp" + ".xml"
    }
	
    stages {
        stage('Prepare Build Environment') {
            steps {
                //sh "rm -rf ${HS_BuildTargetFolder}"
				//sh "mkdir ${HS_BuildTargetFolder}"
                sh 'cd "${WORKSPACE}"'
                // Allow the jenkins user the ability to execute the shell files found in the build folder
                sh "chmod a+x *.sh"
				
				sh "./buildInstallerNamespace.sh $HS_BuildInstance '${WORKSPACE}' '%SYS' $HS_BuildTargetFolder $HS_BuildNamespace $HS_CREDENTIALS_USR $HS_CREDENTIALS_PSW $Git_CREDENTIALS_USR $Git_CREDENTIALS_PSW $Git_RepoURL $Git_SourceBranch $Git_IntBranch"
			}
        }
        stage('Build') {
            steps {
				//sh "echo $HS_DeployFileName"
				
				sh "./buildDeployPackage.sh $HS_BuildInstance $HS_BuildNamespace $HS_DeployFileName $Git_SourceBranch $Git_IntBranch"
			}
        }
		stage('Test') {
            steps {
                sh 'echo "No tests configured"'
            }
        }
		stage('Deploy') {
            steps {
				script {
					readFile('DeployList.csv').split('\n').each { line, count ->
						def fields = line.split(',')
						for (String item: fields) {
							host=fields[0]
							port=fields[1]
							namespace=fields[2]
							sh "./deployRemote.sh $HS_BuildInstance $HS_BuildNamespace $HS_DeployFileName $host $port $namespace"
						}
					}
				}
            }
        }
    }
	post {
		always {
			sh 'echo "maybe post is where to call test"'
		}
    }	
}


