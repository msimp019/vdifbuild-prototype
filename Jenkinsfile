
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
                //sh "rm -rf ${HS_BuildTargetFolder}" //currently not working due to permissions, so I created the folder manually
				//sh "mkdir ${HS_BuildTargetFolder}" //currently not working due to permissions, so I created the folder manually
                sh 'cd "${WORKSPACE}"'
                // Allow the jenkins user the ability to execute the shell files found in the build folder
                sh "chmod a+x *.sh"
				
				sh "./buildInstallerNamespace.sh $HS_BuildInstance '${WORKSPACE}' '%SYS' $HS_BuildTargetFolder $HS_BuildNamespace $HS_CREDENTIALS_USR $HS_CREDENTIALS_PSW $Git_CREDENTIALS_USR $Git_CREDENTIALS_PSW $Git_RepoURL $Git_SourceBranch $Git_IntBranch"
			}
        }
        stage('Build') {
            steps {
				sh "./buildDeployPackage.sh $HS_BuildInstance $HS_BuildNamespace $HS_DeployFileName $Git_SourceBranch $Git_IntBranch"
			}
        }
		stage('Deploy') {
            steps {
				script {
					def result
					def countCompleted
					try {
						readFile('DeployList.csv').split('\n').each { line, count ->
							def fields = line.split(',')
							host=fields[0]
							port=fields[1]
							namespace=fields[2]
							result = sh script: "./deployRemote.sh $HS_BuildInstance $HS_BuildNamespace $HS_DeployFileName $host $port $namespace", returnStatus: true
							echo "$result"
							if (result == 1) { throw new Exception("$result") }
							countCompleted++
						}
					} catch(Exception e) {
						// do nothing, this just to exit the loop
					}
					echo "$result"
					echo "$countCompleted"

				}
            }
        }
		stage('Test') {
            steps {
                sh 'echo "No tests configured"'
            }
        }
    }
	post {
		always {
			sh 'echo "post"'
		}
    }	
}


