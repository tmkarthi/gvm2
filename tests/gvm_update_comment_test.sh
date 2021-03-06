source "${SANDBOX}/gvm2/scripts/gvm"

##
## Test output messages
##

gvm update -h # status=0; match=/Usage: gvm update \[option\] \[<version>\]/
gvm update --help # status=0; match=/Usage: gvm update \[option\] \[<version>\]/

gvm update -l # status=0; match=/Available GVM2 versions/
gvm update --list # status=0; match=/Available GVM2 versions/

## Wait so that we don't get locked out for making too many git api requests
sleep 4

##
## find all versions available
##
## 0.9.0
## 0.9.1
## 0.9.2

## Setup expectation - nothing to do

## Execute command
availableVersions=( $(${SANDBOX}/gvm2/scripts/update --list --porcelain) )

## Evaluate result
for version in "${availableVersions[@]}";do [[ "${version}" == "v0.9.0" ]] && break; done # status=0
for version in "${availableVersions[@]}";do [[ "${version}" == "v0.9.1" ]] && break; done # status=0
for version in "${availableVersions[@]}";do [[ "${version}" == "v0.9.2" ]] && break; done # status=0

## Wait so that we don't get locked out for making too many git api requests
sleep 4

## When running tests locally, the upstream url will use ssh instead of https,
## so we need to fix it here. We will also commit any changes and then roll them
## back at the end.
( builtin cd "${SANDBOX}/gvm2"; mv .git.bak .git; git remote set-url origin https://github.com/markeissler/gvm2.git; git -c user.name=test -c user.email=test@test.com commit -am "Pending"; mv .git .git.bak )

## Switch to latest

## Switch to older version (accept prompt)
yes y | gvm update v0.9.1 # status=0
source "${SANDBOX}/gvm2/scripts/gvm"
gvm version # status=0; match=/0.9.1/

## Wait so that we don't get locked out for making too many git api requests
sleep 4

## Reset install on exit so other tests don't break!
( builtin cd "${SANDBOX}/gvm2"; mv .git.bak .git; git reset --hard $(git rev-list --all --max-count=1); mv .git .git.bak )
