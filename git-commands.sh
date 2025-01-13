#!/bin/bash

# Display the current status of the Git repository
git status

# Add all changes to the staging area
git add .

# Commit the changes with a message
git commit -m "newfile"

# Push the changes to the 'main' branch
git push origin main
