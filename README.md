# Azure Functions using Python project template

This is a project template of Azure Functions using Python with one
sample function and a unit test for it.\
Project is configured for use in VSCode devcontainer. The application
is also configured for deploy in a container.

## Repository layout

``` text
.
├── .azure-pipelines                # Azure DevOps pipeline definition directory
│   └── ...
├── .devcontainer                   # remote-containers configuration files directory
│   └── ...
├── app                             # azure function code which will be deployed
│   ├── configuration               # Python App Configuration handling implementation
│   │   ├── __init__.py
│   │   ├── appconfiguration.py     # retrieving appcf settings including key-vault referenced secrets
│   │   └── config.py               # classes for specific appcf settings
│   ├── function                    # sample Azure Function
│   │   └── ...
│   ├── health                      # health check function used by Azure Function App
│   │   └── ...
│   ├── modules                     # shared app modules
│   │   ├── __init__.py
│   │   ├── database.py             # MS SQL database handling using pandas
│   │   └── datalake.py             # Azure DataLake blob storage handling
│   ├── Dockerfile                  # application container dockerfile
│   ├── ...
│   └── requirements.txt            # application requirements
├── scripts                         # development scripts
│   └── ...
├── terraform                       # terraform template for provisioning Azure Function App
│   └── ...
├── test                            # unit tests folder
│   └── ...
├── .dockerignore                   # dockerignore of application container
├── .gitattributes                  # project specific git settings
├── .gitignore                      # python gitignore
├── conda.ps1                       # PowerShell script for creating conda environment
├── conda.yaml                      # conda environment definition
├── docker-compose.debug.yml        # development docker compose for debugging and testing
├── docker-compose.yml              # docker compose used in pipeline for building container image
├── LICENSE                         # project license
├── pylintrc                        # pylint configuration file
├── pysetup.ps1                     # PowerShell script for setting python venv environment
├── pysetup.sh                      # bash script for setting python venv environment
├── README.md                       # this file
└── requirements.txt                # development requirements
```
