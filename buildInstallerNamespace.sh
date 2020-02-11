#!/usr/bin/expect

set timeout 360

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
set gitEnvBranch			[lindex $argv 10]
set gitIntBranch			[lindex $argv 11]
set cmName					[lindex $argv 12]
set cmEmail					[lindex $argv 13]
set gitBin					[lindex $argv 14]

spawn csession $environment -U $namespace 

# expect "Username:" { send "$userName\r" } timeout { exit 1 }
# expect "Password:" { send "$password\r" } timeout { exit 1 }

expect "${namespace}>" { send "Do ##class(%SYSTEM.OBJ).ImportDir(\"$workspace/User/SourceControl/Build\",\"*.cls\",\"ck\",,1)\r" } timeout { puts "timed out"; exit 1 }

# Run Edge Setup
expect "${namespace}>" { send "Write ##class(User.SourceControl.Build.Installer).setup()\r" } timeout { puts "timed out"; exit 1 }

expect "1\r\n${namespace}>" { send "ZN \"${buildNamespace}\"\r" } timeout { puts "timed out"; exit 1 }

expect "$buildNamespace>" { send "Do ##class(%SYSTEM.OBJ).ImportDir(\"$workspace\",\"*.cls\",\"ck\",,1)\r" } timeout { puts "timed out"; exit 1 }

expect "$buildNamespace>" { send "write \"name: $cmName\"\r"} timeout { puts "timed out"; exit 1 }

expect "$buildNamespace>" { send "write \"$gitBin\"\r"} timeout { puts "timed out"; exit 1 }

expect "$buildNamespace>" { send "Do ##class(%SYSTEM.OBJ).ImportDir(\"$workspace\",\"*.mac\",\"ck\",,1)\r" } timeout { puts "timed out"; exit 1 }

expect "$buildNamespace>" { send "Write ##class(User.SourceControl.Git.Utils).LoadSettings(\"$buildTargetFolder\",\"$gitUserName\",\"$cmName\",\"$cmEmail\",\"\",\"$gitURL\",,,\"$buildNamespace\",\"$gitBin\")\r" } timeout { puts "timed out"; exit 1 }

expect "1\r\n$buildNamespace>" { send "Write ##class(User.SourceControl.Git.Utils).LoadBranch(\"$gitEnvBranch\",\"$gitPassword\")\r" } timeout { puts "timed out"; exit 1 }

expect "1\r\n$buildNamespace>" { send "Write ##class(Ens.Config.Credentials).SetCredential(\"HS_Credentials\",\"$userName\",\"$password\",1)\r" } timeout { puts "timed out"; exit 1 }

expect "1\r\n$buildNamespace>"  { send "H\r"} timeout { puts "timed out"; exit 1 }

exit 0


