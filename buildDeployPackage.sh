#!/usr/bin/expect

set timeout 300

set environment   			[lindex $argv 0]
set buildNamespace			[lindex $argv 1]
set deployFileName			[lindex $argv 2]
set gitEnvBranch			[lindex $argv 3]
set gitIntBranch			[lindex $argv 4]

spawn csession $environment -U "%SYS"

expect "%SYS>" { send "ZN \"${buildNamespace}\"\r" } timeout { puts "timed out"; exit 1 }

expect "$buildNamespace>" { send "Write ##class(User.SourceControl.Git.Utils).BuildDeployment(\"$deployFileName\",\"$gitEnvBranch\",\"$gitIntBranch\")\r" } timeout { puts "timed out"; exit 1 }

expect { 
	"SUCCESS"  { send "H\r"; puts "SUCCESS"; exit 0 }
	"FAILURE"  { send "H\r"; puts "FAILURE"; exit 1 }
}

