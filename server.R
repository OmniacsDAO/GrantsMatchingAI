## Load Libraries
library(bslib)
library(bsicons)
library(tibble)
library(readr)
library(htmltools)

########################################################################
## Help Messages
########################################################################
txtsubseltooltipmsg <- paste0(
							"<dl>",
							"<dt><strong>Complete Grant</strong></dt>",
							"<dd>Encompassing all sections and details whether raw or summarised.</dd>",
							"<dt><strong>Semantic Chunks</strong></dt>",
							"<dd>Segmented portions divided based on semantic meaning or contextual relevance.</dd>",
							"<dt><strong>About You</strong></dt>",
							"<dd>Grant Section regarding applicant or organization, including background and qualifications.</dd>",
							"<dt><strong>Description</strong></dt>",
							"<dd>Grant Section regarding purpose, objectives, and expected outcomes of the project.</dd>",
							"<dt><strong>Goals</strong></dt>",
							"<dd>Grant Section regarding measurable targets and success criteria.</dd>",
							"<dt><strong>Milestones</strong></dt>",
							"<dd>Grant Section regarding key phases or checkpoints in the grant project timeline.</dd>",
							"<dt><strong>Budget Breakdown</strong></dt>",
							"<dd>Grant Section regarding financial plan, itemizing the budgetary requirements and allocation of funds.</dd>",
							"</dl>"
					)
txtsubseltooltip <- tooltip(h6("Data Granularity",bs_icon("info-circle")),HTML(txtsubseltooltipmsg),placement = "auto")
########################################################################
########################################################################


## Load Helper Functions
source("helpers.R")

## Load Grants
gvr <- read_csv("data/DataLatest.csv",show_col_types = FALSE)
gvr$Status <- ifelse(gvr$Status %in% c("Review failed","Denial Confirmed","Expired",NA),"Rejected","Accepted")
gvc <- read_csv("data/grantsVecClean.csv",show_col_types = FALSE)
gvs <- read_csv("data/grantsVecSumm.csv",show_col_types = FALSE)
gvall <- as_tibble(cbind(gvc,gvs[,-1]))
names(gvall)[1:8] <- c("RecordID","Grant Name","Applicant","About You","Description","Goals","Milestones","Funding Request Budget Breakdown")
names(gvall)[9:13] <- c("About You","Description","Goals","Milestones","Funding Request Budget Breakdown")

## Parse Grant Function
parse_grant_card <- function(x)
{
	bgclass <- "bg-danger"
	# if (x[14] >= 70) bgclass <- "bg-success"
	if(gvr$Status[match(x[1],gvr$`Record ID`)]=="Accepted") bgclass <- "bg-success"
	card(
		card_header(class = bgclass,paste0("Project ID : ",x[1],"   With ",x[14],"% Cosine Similarity")),
		max_height = 400,
		full_screen = TRUE,
		tabsetPanel(
    					tabPanel("Grant Raw Text", markdown(paste0(paste("<strong>",names(x)[c(2,3:8)],"</strong>","<br/>",x[c(2,3:8)]),collapse="<br/><br/>"))),
    					tabPanel("Grant LLM Summarised", markdown(paste0(paste("<strong>",names(x)[c(2,3,9:13)],"</strong>","<br/>",x[c(2,3,9:13)]),collapse="<br/><br/>"))),
    					tabPanel("Matching Result", markdown(paste0(paste("<strong>",names(x)[15:16],"</strong>","<br/>",x[15:16]),collapse="<br/><br/>"))),
  		)
	)
}

server <- function(input, output, session) {#bs_themer()

	########################################################################
	## UI Matches and Output
	########################################################################
	output$matchui <- renderUI({
									sellist <- list(
													"Complete Grant"="fullgtxt",
													"Semantic Chunks"="semctxt",
													"About You" = "abttxt",
													"Description" = "desctxt",
													"Goals" = "glstxt",
													"Milestones" = "mlstxt",
													"Budget Breakdown" = "bbtxt"

												)
									if(input$txtsel=="rawtxt") sellist <- sellist[1:2]
									selectInput("txtsubsel",label = txtsubseltooltip,choices=sellist,selected = "semctxt")
						})
	output$matches <- renderUI({
									if(is.null(matchdata$matches)) return(NULL)
									## Matches
									cmatches <- matchdata$matches
									matchUI <- list(layout_column_wrap(width = 1,!!!apply(cmatches,1,parse_grant_card,simplify=FALSE)))
									return(matchUI)
						})
	########################################################################
	########################################################################


	########################################################################
	## Matching
	########################################################################
	matchdata <- reactiveValues(matches=NULL)
	observeEvent(input$gomatch,{
								query <- input$query
								if(query!="")
								{
									progress <- shiny::Progress$new();on.exit(progress$close());progress$set(message = "Matching Grants", value = .5)
									
									## Find Respected Retreival
									if(input$txtsel=="rawtxt")
									{
										if(input$txtsubsel=="fullgtxt") retreiver <- FullRawRS
										if(input$txtsubsel=="semctxt") retreiver <- semanticChunksRawRS
									}
									if(input$txtsel=="sumtxt")
									{
										if(input$txtsubsel=="fullgtxt") retreiver <- FullSummaryRS
										if(input$txtsubsel=="semctxt") retreiver <- semanticChunksRS
										if(input$txtsubsel=="abttxt") retreiver <- AboutYouRS
										if(input$txtsubsel=="desctxt") retreiver <- ProjectDescriptionRS
										if(input$txtsubsel=="glstxt") retreiver <- ProjectGoalsRS
										if(input$txtsubsel=="mlstxt") retreiver <- MilestonesRS
										if(input$txtsubsel=="bbtxt") retreiver <- FundingRequestBudgetBreakdownRS
									}

									## Retreive Matches
									matchres <- retreiver(query)
									matchresp <- data.frame(row = sapply(matchres,"[[",1),score = sapply(matchres,"[[",2),text = sapply(matchres,"[[",3))
									matchresp$score <- 1-matchresp$score
									matchrespl <- split(matchresp,matchresp$row)
									matchresf <- do.call(rbind,lapply(matchrespl,function(x) x[which.max(x$score),]))
									tdata <- gvall[gvall$`RecordID` %in% matchresf$row,]
									tdata$CosineSimilarity <- round(100*matchresf$score[match(tdata$`RecordID`,matchresf$row)])
									tdata$`User Query` <- query
									tdata$`Embedding Match` <- matchresf$text[match(tdata$`RecordID`,matchresf$row)]
									tdata <- head(tdata[order(tdata$CosineSimilarity,decreasing=TRUE),],3)
									matchdata$matches <- tdata
								}
				})
	########################################################################
	########################################################################
}