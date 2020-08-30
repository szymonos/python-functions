<#
.SYNOPSIS
.LINK
https://stackoverflow.com/questions/1828874/generating-statistics-from-git-repository
.EXAMPLE
#>

$rev=2; $date = (Get-Date).ToString('yyMMdd'); git checkout -b "szymono_$date-$rev"
git add .
git commit -m "update $date-1"
git push -u origin head
git checkout dev
git pull

# Statistics
git shortlog -sn --no-merges
git shortlog -sne
git shortlog -s -n --since "2020-01-01"
git shortlog -s -n --since "2019-01-01"

# Number of files in repository
(git ls-files).Count

# create new branch, add changes, commit and checkout to starting branch
git checkout master
git pull
git checkout -b lang-ds-triggers
git add .
git commit -m 'Update lang datasync triggers'
git push -u origin head
git checkout master

# stash changes, change branch and pop stash
git add .  # stage all changes
git stash  # stash all changes
git checkout dev  # change branch
git stash list  # list all stashed changes
git stash pop  # po stash
