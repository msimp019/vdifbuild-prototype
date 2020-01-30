# vdifbuild-prototype


##Jenkins configuration
1. The jenkin's build in each environment must be configured to have a global environment variable under Manage Jenkins => Configure. 
Required Variables: Git_SourceBranch, Git_IntBranch, Git_RepoURL
ex:
```
Git_SourceBranch = 'develop'
Git_IntBranch = 'int/develop'
Git_RepoURL = 'github.com/msimp019/vdif-prototype.git'
```