## Load Libraries
library(reticulate)

## Load Variables
source("0_Environment.R")

## Python Environment
use_virtualenv("grantsAI",required=TRUE)

## Load Libraries
py_run_string('
import os
from langchain_community.document_loaders import DataFrameLoader
from langchain_community.document_loaders.csv_loader import CSVLoader
from langchain_experimental.text_splitter import SemanticChunker
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.llms import Ollama
from langchain_chroma import Chroma
import pandas as pd
')

## Embedding Model
py_run_string(paste0('embeddings_model = OllamaEmbeddings(base_url = "',ollamaHostPrepare,'", model="',ollamaEmbdModel,'", num_ctx=',ollamaEmbd_num_ctx,')'))

## LLM Model
py_run_string(paste0('llm_model = Ollama(base_url = "',ollamaHostPrepare,'", model="',ollamaLLMModel,'", num_ctx=',ollamaLLM_num_ctx,')'))
py_run_string('template = "For the above context respond concise 5 line paragraph meaningful summary. Do your best due dilligence while performing this task and make sure to not include any introductory or concluding phrases like here is n line summary, Just return plain summary itself. Only pick the key information."')

## Load and Prep data
py_run_string('
## Load Data
df = pd.read_csv("data/grantsVec.csv")
df = df.rename(columns={"Record ID": "RecordID", "Project Name": "Projectname", "Applicant Name":"ApplicantName", "About You":"AboutYou", "Project Description":"ProjectDescription", "Project Goals":"ProjectGoals", "Funding Request and Budget Breakdown":"FundingRequestBudgetBreakdown"})
df.to_csv("data/grantsVecClean.csv",index=False)

## Summarise Data
df = df.assign(AboutYouN = llm_model.batch([str(s) + template for s in df.AboutYou.tolist()]))
df = df.assign(ProjectDescriptionN = llm_model.batch([str(s) + template for s in df.ProjectDescription.tolist()]))
df = df.assign(ProjectGoalsN = llm_model.batch([str(s) + template for s in df.ProjectGoals.tolist()]))
df = df.assign(MilestonesN = llm_model.batch([str(s) + template for s in df.Milestones.tolist()]))
df = df.assign(FundingRequestBudgetBreakdownN = llm_model.batch([str(s) + template for s in df.FundingRequestBudgetBreakdown.tolist()]))

## Create Embeddings For each Text Column
AboutYouDF = DataFrameLoader(df[["RecordID","AboutYouN"]], page_content_column="AboutYouN").load()
ProjectDescriptionDF = DataFrameLoader(df[["RecordID","ProjectDescriptionN"]], page_content_column="ProjectDescriptionN").load()
ProjectGoalsDF = DataFrameLoader(df[["RecordID","ProjectGoalsN"]], page_content_column="ProjectGoalsN").load()
MilestonesDF = DataFrameLoader(df[["RecordID","MilestonesN"]], page_content_column="MilestonesN").load()
FundingRequestBudgetBreakdownDF = DataFrameLoader(df[["RecordID","FundingRequestBudgetBreakdownN"]], page_content_column="FundingRequestBudgetBreakdownN").load()
AboutYouVS = Chroma.from_documents(AboutYouDF, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="AboutYouVS")
ProjectDescriptionVS = Chroma.from_documents(ProjectDescriptionDF, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="ProjectDescriptionVS")
ProjectGoalsVS = Chroma.from_documents(ProjectGoalsDF, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="ProjectGoalsVS")
MilestonesVS = Chroma.from_documents(MilestonesDF, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="MilestonesVS")
FundingRequestBudgetBreakdownVS = Chroma.from_documents(FundingRequestBudgetBreakdownDF, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="FundingRequestBudgetBreakdownVS")

## Semantic Full Embeddings
df[["RecordID","AboutYouN","ProjectDescriptionN","ProjectGoalsN","MilestonesN","FundingRequestBudgetBreakdownN"]].to_csv("data/grantsVecSumm.csv",index=False)
loader = CSVLoader(file_path="data/grantsVecSumm.csv", encoding="utf-8", csv_args={"delimiter": ","},source_column="RecordID",metadata_columns=["RecordID"])
sfData = loader.load()
FullSummaryVS = Chroma.from_documents(sfData, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="FullSummaryVS")

## Semantic Chunker Embeddings
semantic_splitter = SemanticChunker(embeddings_model)
semanticChunks = semantic_splitter.split_documents(sfData)
semanticChunksVS = Chroma.from_documents(semanticChunks, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="semanticChunksVS")

## Raw Data Embeddings
loader = CSVLoader(file_path="data/grantsVecClean.csv", encoding="utf-8", csv_args={"delimiter": ","},source_column="RecordID",metadata_columns=["RecordID"])
rfData = loader.load()
FullRawVS = Chroma.from_documents(rfData, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="FullRawVS")

## Raw Data Semantic Chunker Embeddings
semantic_splitter = SemanticChunker(embeddings_model)
semanticChunksRaw = semantic_splitter.split_documents(rfData)
semanticChunksRawVS = Chroma.from_documents(semanticChunksRaw, embeddings_model, collection_metadata={"hnsw:space": "cosine"}, persist_directory="data/Embeddings", collection_name="semanticChunksRawVS")
')