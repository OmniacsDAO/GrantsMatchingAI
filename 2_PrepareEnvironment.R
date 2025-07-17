## Load Libraries
library(reticulate)

## Python Environment
use_python("/usr/bin/python3")
virtualenv_create("grantsAI")
virtualenv_install(envname="grantsAI",packages=c("langchain","langchain-core","langchain-community","langchain-experimental","langchain-chroma","langchain_ollama","pandas"))
# use_virtualenv("grantsAI",required=TRUE)