#!/bin/sh
# cf. https://blog.bloomca.me/2017/12/15/how-to-push-folder-to-github-pages.html

# get main repo configs
ORIGIN=`git config remote.origin.url`
UMAIL=`git config user.email`
UNAME=`git config user.name`
# get current time
TIME=`date --rfc-3339=seconds`

cd www
# remove existing .git just in case
rm -rf .git

# create an ephemeral git repo and deploy
git init
git config user.email $UMAIL
git config user.name $UNAME
git add .
git commit -m "Deployed at $TIME"
git remote add origin $ORIGIN
git push --force origin master:gh-pages

# clean up
rm -rf .git
