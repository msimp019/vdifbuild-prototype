#!/usr/bin/expect

set timeout 60

set environment   			[lindex $argv 0]
set buildNamespace			[lindex $argv 1]
set deployFileName			[lindex $argv 2]
set targetHost				[lindex $argv 3]
set targetPort				[lindex $argv 4]
set targetNamespace			[lindex $argv 5]
set jenkinsEnvironment		[lindex $argv 6]

spawn csession $environment -U $buildNamespace 

expect "$buildNamespace>" { send "set ^VDIF(\"environment\")=\"$jenkinsEnvironment\""} timeout { puts "timed out"; exit 1 }

expect "$buildNamespace>" { send "Write ##class(User.SourceControl.Git.Utils).Deploy(\"$deployFileName\",\"$targetHost\",\"$targetPort\",\"$targetNamespace\")\r" } timeout { puts "timed out"; exit 1 }

expect { 
	"SUCCESS"  { send "H\r"; puts "SUCCESS"; exit 0 }
	"FAILURE"  { send "H\r"; puts "FAILURE"; exit 1 }
	
}


