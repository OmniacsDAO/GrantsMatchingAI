## Load Libraries
library(readr)

## Parse Data
data <- read_csv("data/DataLatest.csv",show_col_types = FALSE)
dataVec <- data[,c(2,1,4,7,11,13,14,15)]

## Save Data
write_csv(dataVec,"data/grantsVec.csv")