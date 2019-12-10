#!/usr/bin/expect

set timeout 60

set environment   			[lindex $argv 0]
set buildNamespace			[lindex $argv 1]
set deployFilePath			[lindex $argv 2]
set deployFileName			[lindex $argv 3]
set gitSourceBranch			[lindex $argv 4]
set gitIntBranch			[lindex $argv 5]

spawn csession $environment -U $buildNamespace 

expect "$buildNamespace>" { send "Write ##class(User.SourceControl.Git.Utils).BuildDeployment(\"$deployFilePath\",\"$deployFileName\",\"$gitIntBranch\",\"$gitSourceBranch\")\r" } timeout { exit 1 }

expect "$buildNamespace>"  { send "H\r"}


