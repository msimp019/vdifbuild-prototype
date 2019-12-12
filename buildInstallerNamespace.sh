#!/usr/bin/expect

set timeout 60

set environment   			[lindex $argv 0]
set workspace     			[lindex $argv 1]
set namespace     			[lindex $argv 2]
set buildTargetFolder		[lindex $argv 3]
set buildNamespace			[lindex $argv 4]
set userName				[lindex $argv 5]
set password				[lindex $argv 6]
set gitUserName				[lindex $argv 7]
set gitPassword				[lindex $argv 8]
set gitURL					[lindex $argv 9]
set gitSourceBranch			[lindex $argv 10]
set gitIntBranch			[lindex $argv 11]

spawn csession $environment -U $namespace 

# expect "Username:" { send "$userName\r" } timeout { exit 1 }
# expect "Password:" { send "$password\r" } timeout { exit 1 }

# Remove previous HealthShare classes
# expect "${namespace}>" { send "Do ##class(%SYSTEM.OBJ).Delete(\"HS.Local.VA*\")\r" } timeout { exit 1 }

# Deploy RC.Channels.Edge* Classes
expect "${namespace}>" { send "Do ##class(%SYSTEM.OBJ).Load(\"$workspace/BuildInstaller.cls.xml\",\"cbfk\")\r" } timeout { exit 1 }

# Run Edge Setup
expect "${namespace}>" { send "Write ##class(User.SourceControl.Build.Installer).setup()\r" } timeout { exit 1 }

expect "${namespace}>" { send "ZN \"${buildNamespace}\"\r" } timeout { exit 1 }

expect "$buildNamespace>" { send "Do ##class(%SYSTEM.OBJ).Load(\"$workspace/SourceControl.Git.cls.xml\",\"cbfk\")\r" } timeout { exit 1 }

expect "$buildNamespace>" { send "Do ##class(%SYSTEM.OBJ).Load(\"$workspace/SourceControl.Deploy.cls.xml\",\"cbfk\")\r" } timeout { exit 1 }

expect "$buildNamespace>" { send "Do ##class(User.SourceControl.Git.Utils).LoadSettings(\"$buildTargetFolder\",\"$gitUserName\",\"$gitURL\",\"https\",\"Matthew Simpson\",\"matthew.simpson@readycomputing.com\")\r" } timeout { exit 1 }

expect "$buildNamespace>" { send "Do ##class(User.SourceControl.Git.Utils).LoadBranch(\"$gitIntBranch\",\"$gitPassword\")\r" } timeout { exit 1 }

expect "$buildNamespace>" { send "Do ##class(Ens.Config.Credentials).SetCredential(\"HS_Credentials\",\"$userName\",\"$password\",1)\r" } timeout { exit 1 }

expect "$buildNamespace>"  { send "H\r"}


