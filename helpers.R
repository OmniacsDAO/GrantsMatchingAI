## Load Libraries
library(reticulate)

## Load Variables
source("0_Environment.R")

## Python Environment
use_virtualenv("grantsAI",required=TRUE)

## Setup Python modules
py_run_string('
import os
from langchain_community.embeddings import OllamaEmbeddings
from langchain_chroma import Chroma
from typing import List
from langchain_core.documents import Document
from langchain_core.runnables import chain
')

## Embeddings Model
py_run_string(paste0('embeddings_model = OllamaEmbeddings(base_url = "',ollamaHostQuery,'", model="',ollamaEmbdModel,'", num_ctx=',ollamaEmbd_num_ctx,')'))

## Load Embeddings
py_run_string('
AboutYouVS = Chroma(embedding_function=embeddings_model,collection_name="AboutYouVS", persist_directory="data/Embeddings")
ProjectDescriptionVS = Chroma(embedding_function=embeddings_model,collection_name="ProjectDescriptionVS", persist_directory="data/Embeddings")
ProjectGoalsVS = Chroma(embedding_function=embeddings_model,collection_name="ProjectGoalsVS", persist_directory="data/Embeddings")
MilestonesVS = Chroma(embedding_function=embeddings_model,collection_name="MilestonesVS", persist_directory="data/Embeddings")
FundingRequestBudgetBreakdownVS = Chroma(embedding_function=embeddings_model,collection_name="FundingRequestBudgetBreakdownVS", persist_directory="data/Embeddings")
FullSummaryVS = Chroma(embedding_function=embeddings_model,collection_name="FullSummaryVS", persist_directory="data/Embeddings")
semanticChunksVS = Chroma(embedding_function=embeddings_model,collection_name="semanticChunksVS", persist_directory="data/Embeddings")
FullRawVS = Chroma(embedding_function=embeddings_model,collection_name="FullRawVS", persist_directory="data/Embeddings")
semanticChunksRawVS = Chroma(embedding_function=embeddings_model,collection_name="semanticChunksRawVS", persist_directory="data/Embeddings")
')

## Make Custom Retreiver Builder
py_run_string('
def customRetreiverScorer(anyVS):
    @chain
    def retrieverRaw(query: str) -> List[Document]:
        docs, scores = zip(*anyVS.similarity_search_with_score(query,k=100))
        for doc, score in zip(docs, scores):
            doc.metadata["score"] = score
        return docs
    return(retrieverRaw)

def getmatch(x): return {"source":x.metadata["RecordID"],"score":x.metadata["score"],"text":x.page_content}
')

## R function to get matches and answer queries
AboutYouRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(AboutYouVS).invoke("',gsub("\n","\\n",query),'")))'))
ProjectDescriptionRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(ProjectDescriptionVS).invoke("',gsub("\n","\\n",query),'")))'))
ProjectGoalsRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(ProjectGoalsVS).invoke("',gsub("\n","\\n",query),'")))'))
MilestonesRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(MilestonesVS).invoke("',gsub("\n","\\n",query),'")))'))
FundingRequestBudgetBreakdownRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(FundingRequestBudgetBreakdownVS).invoke("',gsub("\n","\\n",query),'")))'))
FullSummaryRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(FullSummaryVS).invoke("',gsub("\n","\\n",query),'")))'))
semanticChunksRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(semanticChunksVS).invoke("',gsub("\n","\\n",query),'")))'))
FullRawRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(FullRawVS).invoke("',gsub("\n","\\n",query),'")))'))
semanticChunksRawRS <- function(query) py_eval(paste0('list(map(getmatch, customRetreiverScorer(semanticChunksRawVS).invoke("',gsub("\n","\\n",query),'")))'))