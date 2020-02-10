
def HS_BuildTargetFolder = '/opt/VABUILD/'
def HS_BuildInstance = env.HS_Instance
def HS_BuildNamespace = 'VABUILD'
def Git_EnvBranch = env.Git_EnvBranch
def Git_IntBranch = env.Git_IntBranch
def Git_RepoURL = env.Git_RepoURL
def Git_Bin = env.Git_Bin
def HS_Environment = env.HS_Environment
def CM_Name = env.CM_Name
def CM_Email = env.CM_Email
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
				sh echo $Git_Bin
				echo $Git_Bin
				sh "./buildInstallerNamespace.sh $HS_BuildInstance '${WORKSPACE}' '%SYS' $HS_BuildTargetFolder $HS_BuildNamespace $HS_CREDENTIALS_USR $HS_CREDENTIALS_PSW $Git_CREDENTIALS_USR $Git_CREDENTIALS_PSW $Git_RepoURL $Git_EnvBranch $Git_IntBranch $CM_Name $CM_Email $Git_Bin"
			}
        }
        stage('Build') {
            steps {
            	sh "echo $HS_BuildInstance"
            	sh "echo $HS_BuildNamespace"
				sh "./buildDeployPackage.sh $HS_BuildInstance $HS_BuildNamespace $HS_DeployFileName $Git_EnvBranch $Git_IntBranch"
			}
        }
		stage('Deploy') {
            steps {
				script {
					def result
					def countCompleted = 0
					try {
						readFile('DeployList.csv').split('\n').each { line, count ->
							def fields = line.split(',')
							host=fields[0]
							port=fields[1]
							namespace=fields[2]
							result = sh script: "./deployRemote.sh $HS_BuildInstance $HS_BuildNamespace $HS_DeployFileName $host $port $namespace $HS_Environment", returnStatus: true
							if (result == 1) { throw new Exception("$result") }
							countCompleted = countCompleted + 1
						}
					} catch(Exception e) {
						readFile('DeployList.csv').split('\n').eachWithIndex { line, index ->
							if (index <= countCompleted) { 
								def fields = line.split(',')
								host=fields[0]
								port=fields[1]
								namespace=fields[2]
								sh "./deployRemoteRollback.sh $HS_BuildInstance $HS_BuildNamespace $HS_DeployFileName $host $port $namespace"
							}
						}
						//Fail the stage after doing the rollbacks
						sh "exit 1"
					}

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

