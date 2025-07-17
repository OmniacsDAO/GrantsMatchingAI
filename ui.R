## Load Libraries
library(shiny)
library(bslib)
library(bsicons)
library(htmltools)

########################################################################
## Help Messages
########################################################################
txtseltootipmsg <- paste0(
							"<dl>",
							"<dt><strong>Raw Text</strong></dt>",
							"<dd>The raw text from the Grant is embedded.</dd>",
							"<dt><strong>LLM Summarised Text</strong></dt>",
							"<dd>The raw text is summarised using LLM and then embedded.</dd>",
							"</dl>"
					)
txtseltooltip <- tooltip(h6("Grants Data Source",bs_icon("info-circle")),HTML(txtseltootipmsg),placement = "auto")
########################################################################
########################################################################

ui <- fluidPage(title = "AI Grant Matching App",theme =  bs_theme(version = 5,bootswatch="morph")|> bs_add_variables("tooltip-max-width"="400px","tooltip-opacity" = .75),

	########################################################################
	## Logo
	########################################################################
	br(),tags$div(style = "text-align: center;", tags$img(src = "OmniacsDAO.png", width=100)),br(),

	########################################################################
	########################################################################

	
	########################################################################
	## Text Input and Match Cards
	########################################################################
	fluidRow(
		layout_column_wrap(
			card(width=100,
				fluidRow(
					column(6,selectInput("txtsel",label = txtseltooltip,choices=list("Raw Text"="rawtxt","LLM Summarised Text"="sumtxt"),selected = "sumtxt")),
					column(6,uiOutput("matchui"))
				),
				textAreaInput("query", label=NULL, value = "", width = "100%", height = "500px", placeholder = "Type Here..."),
				actionButton("gomatch", label = "Find Matching Grants")
			),
			card(uiOutput("matches"))
		)	
	),
	tags$div(style = "text-align: center; font-size: 0.9rem;",
    			HTML("&#x1F49A; Like this project? Support more like it with <a href='https://dexscreener.com/base/0xd4d742cc8f54083f914a37e6b0c7b68c6005a024' target='_blank'><strong>$IACS</strong></a> on Base — CA: 0x46e69Fa9059C3D5F8933CA5E993158568DC80EBf")
  	),
  	br(),
	########################################################################
	########################################################################
)