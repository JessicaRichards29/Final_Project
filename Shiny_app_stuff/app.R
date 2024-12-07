library(shiny)
library(tidyverse)
library(modelr)

tree_dat <- read_csv('Tree_Data.csv')
mod_shiny <- glm(data = tree_dat, Phenolics ~ Light_ISF * Species)

df_shiny <- tree_dat %>% 
  add_predictions(mod_shiny) 
#don't need this
df_shiny %>% dplyr::select("Phenolics","pred")

new_shiny_df = data.frame(Species = c('Acer saccharum', 'Prunus serotina', 'Quercus alba', 'Quercus rubra', NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA), 
                          Light_ISF = c(.1, .2, .3, .4, .5, .6, .7, .8, .9, .10, .11, .12, .13, .14, .15, .16, .17, .18, .19, .20))

pred_shiny = predict(mod_shiny, newdata = new_shiny_df)

hyp_preds_shiny <- data.frame(Species = new_shiny_df$Species,
                              Light_ISF = new_shiny_df$Light_ISF,
                              pred_shiny = pred_shiny)

df_shiny$PredictionType <- "Real"
hyp_preds_shiny$PredictionType <- "Hypothetical"

fullpreds_shiny <- full_join(df_shiny,hyp_preds_shiny)



# UI definition
ui <- fluidPage(
  titlePanel("Light_ISF v Phenolics Interactive Plot"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("num", "Choose a Light_ISF value:", min = .01, max = .2, value = .2, step = 0.01)
    ),
    
    mainPanel(
      plotOutput("plot1", click = "plot_click"),
      verbatimTextOutput("info")
    )
  )
)

# Server function definition
server <- function(input, output) {
  
  output$plot1 <- renderPlot({
    new_data <- data.frame(
      Light_ISF = input$num,
      Species = rep(unique(fullpreds_shiny$Species), each = length(input$num))
    )
    new_data$pred_shiny <- predict(mod_shiny, newdata = new_data)
    combined_data <- bind_rows(
      fullpreds_shiny %>% filter(Light_ISF == input$num),  # Real data for selected Light_ISF
      new_data %>% mutate(PredictionType = "Hypothetical")  # New hypothetical data
    )
    
    ggplot() +
      geom_point(data = fullpreds_shiny, 
                 aes(x = Light_ISF, y = Phenolics, color = Species), 
                 alpha = 0.5, size = 1.5) + 
      geom_point(data = combined_data, 
                 aes(x = Light_ISF, y = pred_shiny, 
                     label = Species), size = 3) +
      geom_text(data = combined_data , 
                aes(x = Light_ISF, y = pred_shiny, label = Species), 
                vjust = -0.8, size = 4) +
      scale_color_manual(values = c("Acer saccharum" = "blue", 
                                    "Prunus serotina" = "orange", 
                                    "Quercus alba" = "darkgreen", 
                                    "Quercus rubra" = "purple")) + 
      labs(title = paste("Predictions for Light_ISF =", input$num),
           x = "Light_ISF", y = "Phenolics Prediction") +
      theme_minimal() +
      theme(legend.title = element_blank()) +
      xlim(0, .21) +
      ylim(-1, 6)
    
    
  })
  output$info <- renderPrint({
    req(input$plot_click)
    paste("You clicked at", round(input$plot_click$x, 2), "on the x-axis")
  })
}

# Run the Shiny app
shinyApp(ui = ui, server = server)

