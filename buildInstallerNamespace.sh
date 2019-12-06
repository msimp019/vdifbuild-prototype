#!/usr/bin/expect

set timeout 200

set environment   			[lindex $argv 0]
set workspace     			[lindex $argv 1]
set namespace     			[lindex $argv 2]
set buildTargetFolder		[lindex $argv 3]
set buildNamespace			[lindex $argv 4]

spawn csession $environment -U $namespace 

printenv

expect "Username:" { send "$HS_CREDENTIALS_USR\r" } timeout { exit 1 }
expect "Password:" { send "$HS_CREDENTIALS_PSW\r" } timeout { exit 1 }

# Remove previous HealthShare classes
# expect "${namespace}>" { send "Do ##class(%SYSTEM.OBJ).Delete(\"HS.Local.VA*\")\r" } timeout { exit 1 }

# Deploy RC.Channels.Edge* Classes
expect "${namespace}>" { send "Do ##class(%SYSTEM.OBJ).Load(\"$workspace/BuildInstaller.cls.xml\",\"cbfk\")\r" } timeout { exit 1 }

# Run Edge Setup
expect "${namespace}>" { send "Write ##class(User.SourceControl.Build.Installer).setup()\r" } timeout { exit 1 }

expect "${namespace}>" { send "ZN \"${buildNamespace}\"\r" } timeout { exit 1 }

expect "$buildNamespace" { send "Do ##class(%SYSTEM.OBJ).Load(\"$workspace/SourceControl.Git.cls.xml\",\"cbfk\")\r" } timeout { exit 1 }

expect "$buildNamespace"  { send "H\r"}
