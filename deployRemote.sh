#!/bin/bash

# Parameters
# $1=HealthShare Instance Name
# $2=WorkSpace Directory (Jenkins)
# $3=HealthShare UserName
# $4=HealthShare Password
# $5=Branch identifier (Develop,Stage,Prod)
# $6=Deploy IP@User
# $7=HealthShare Environment Name (Develop,Sit,Demo,Prod)

# Variables
DEPLOYFILE=onerecord-${BUILD_NUMBER}.tar.gz

# Remote Deployment
# Set Remote deployment variables
ACCESSKEY="-i /var/lib/jenkins/workspace/OneRecord.pem"
REMOTESERVER=$6
DEPLOYFULLDIR="~/deploy/"${BUILD_NUMBER}

echo "Remote Deployment..."
echo "Access Key: "${ACCESSKEY}
echo "Remote Server: "${REMOTESERVER}
echo "Deploy tar file: "${2}/deploy/$DEPLOYFILE
echo "Deploy target directory: "${DEPLOYFULLDIR}

# Create deploy folder 
ssh ${ACCESSKEY} ${REMOTESERVER} "mkdir -p $DEPLOYFULLDIR"

# Copy tar file
scp ${ACCESSKEY} ${2}/deploy/$DEPLOYFILE ${REMOTESERVER}:"~/deploy"

# Untar build
ssh ${ACCESSKEY} ${REMOTESERVER} "tar -xf ~/deploy/$DEPLOYFILE --directory $DEPLOYFULLDIR"

# Change owner and mode
ssh ${ACCESSKEY} ${REMOTESERVER} "chmod -R a+x $DEPLOYFULLDIR/*"

# Deploy Remote
INSTANCENAME=$1
REMOTEFOLDER="~/deploy/"${BUILD_NUMBER}${WORKSPACE}

ssh -i /var/lib/jenkins/workspace/OneRecord.pem ${REMOTESERVER} "cd $REMOTEFOLDER/ ; ./expect.sh $INSTANCENAME $REMOTEFOLDER $3 $4 $5 $7"

# Deploy xslt
echo "Deploying XSLT..."
echo "FROM: "${REMOTEFOLDER}/xslt
DEPLOYXSLTDIR="/intersystems/"${INSTANCENAME}"/csp"
echo "  TO: "${DEPLOYXSLTDIR}
ssh -i /var/lib/jenkins/workspace/OneRecord.pem ${REMOTESERVER} "cd $REMOTEFOLDER/ ; sudo cp -R xslt $DEPLOYXSLTDIR"

# Deploy test files
echo "Deploying Test Files..."
echo "FROM: "${REMOTEFOLDER}/testfiles
DEPLOYTESTFILEDIR="/intersystems"
echo "  TO: "${DEPLOYTESTFILEDIR}
ssh -i /var/lib/jenkins/workspace/OneRecord.pem ${REMOTESERVER} "cd $REMOTEFOLDER/ ; sudo cp -R testfiles $DEPLOYTESTFILEDIR"