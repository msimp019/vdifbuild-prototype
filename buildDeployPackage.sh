#!/usr/bin/expect

set timeout 60

set environment   			[lindex $argv 0]
set buildNamespace			[lindex $argv 1]
set deployFileName			[lindex $argv 2]
set gitSourceBranch			[lindex $argv 3]
set gitIntBranch			[lindex $argv 4]

spawn csession $environment -U $buildNamespace 

expect "$buildNamespace>" { send "Do ##class(User.SourceControl.Git.Utils).BuildDeployment(\"$deployFileName\",\"$gitIntBranch\",\"$gitSourceBranch\")\r" } timeout { exit 1 }

expect "$buildNamespace>"  { send "H\r"}


