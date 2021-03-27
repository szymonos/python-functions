# Azure Functions using Python project template

This is a project template of Azure Functions using Python with one
sample function and a unit test for it.\
Project is configured for use in VSCode devcontainer. The application
is also configured for deploy in a container.

## Repository layout

```
.devcontainer               # remote-containers configuration files
 | - Dockerfile
 | - devcontainer.json
app                         # azure function code which will be deployed
 | - function
 | | - function.json
 | | - __init__.py
 | - modules
 | | - __init__.py
 | | - ...
 | - Dockerfile             # application container dockerfile
 | - host.json
 | - requirements.txt       # application requirements
scripts                     # development scripts
 | - __init__.py
 | - ...
test                        # unit tests folder
 | - __init__.py
 | - test_function.py
.dockerignore               # dockerignore of application container
.gitattributes              # python gitignore
.gitignore                  # project specific git settings
LICENCSE                    # project license
pylintrc                    # pylint configuration file
README.md                   # this file
pysetup.ps1                 # powershell script for setting python environment
pysetup.sh                  # bash script for setting python environment
requirements.txt            # development requirements
docker-compose.debug.yml    # application docker-compose file for development
docker-compose.yml          # application docker-compose file
