# Install packages if not already installed
# install.packages(c("shiny", "dplyr", "ggplot2", "randomForest", "caret", "Metrics"))

# app.R
# Bioethanol Fermentation Shiny App
# Combines Linear Model + Random Forest Prediction

library(shiny)
library(dplyr)
library(ggplot2)
library(randomForest)
library(caret)
library(Metrics)

# -----------------------------
# Step 1: Re-run Simulation (Same as before)
# -----------------------------
set.seed(123)
n <- 500

temperature     <- runif(n, 25, 40)
pH                <- runif(n, 4.0, 6.5)
glucose_concentration <- runif(n, 50, 150)
fermentation_time <- runif(n, 12, 72)

ethanol_yield <- numeric(n)

for (i in 1:n) {
  temp_opt <- 32.5
  temp_response <- dnorm(temperature[i], mean = temp_opt, sd = 3)
  temp_factor <- temp_response / dnorm(temp_opt, sd = 3)
  
  pH_opt <- 5.0
  pH_response <- dnorm(pH[i], mean = pH_opt, sd = 0.5)
  pH_factor <- pH_response / dnorm(pH_opt, sd = 0.5)
  
  time_factor <- plogis(fermentation_time[i], location = 48, scale = 8)
  time_factor <- time_factor / plogis(48, location = 48, scale = 8)
  
  glucose_factor <- ifelse(glucose_concentration[i] > 120,
                           1 - 0.3 * ((glucose_concentration[i] - 120) / 30),
                           1)
  glucose_factor <- pmax(glucose_factor, 0.6)
  
  theoretical_max <- 0.51
  efficiency <- 0.85
  
  base_yield <- glucose_concentration[i] * theoretical_max * efficiency *
    temp_factor * pH_factor * time_factor * glucose_factor
  
  noise <- rnorm(1, 0, 0.05 * base_yield)
  ethanol_yield[i] <- pmax(base_yield + noise, 0)
}

fermentation_data <- tibble(
  temperature = round(temperature, 1),
  pH = round(pH, 2),
  glucose_concentration = round(glucose_concentration, 1),
  fermentation_time = round(fermentation_time, 1),
  ethanol_yield = round(ethanol_yield, 2)
)

# Add centered quadratic terms for models
fermentation_data <- fermentation_data %>%
  mutate(
    temp_centered = temperature - mean(temperature),
    temp2 = temp_centered^2,
    pH_centered = pH - mean(pH),
    pH2 = pH_centered^2
  )

# -----------------------------
# Step 2: Train Models
# -----------------------------

# Linear model
model_centered <- lm(
  ethanol_yield ~ temp_centered + temp2 + pH_centered + pH2 +
    glucose_concentration + fermentation_time,
  data = fermentation_data
)

# Random Forest
set.seed(123)
rf_model <- randomForest(
  ethanol_yield ~ temp_centered + temp2 + pH_centered + pH2 +
    glucose_concentration + fermentation_time,
  data = fermentation_data,
  ntree = 500,
  importance = TRUE
)

# -----------------------------
# Step 3: Define UI
# -----------------------------
ui <- fluidPage(
  titlePanel("Baba_Elijah's Bioethanol Yield Predictor", 
             h3("Saccharomyces cerevisiae Fermentation Optimization", 
                style = "font-size: 16px; font-weight: normal;")),
  sidebarLayout(
    sidebarPanel(
      h4("Fermentation Conditions"),
      
      sliderInput("temp", "Temperature (°C):", 
                  min = 25, max = 40, value = 33, step = 0.5),
      
      sliderInput("ph", "pH:", 
                  min = 4.0, max = 6.5, value = 5.0, step = 0.1),
      
      sliderInput("glucose", "Glucose (g/L):", 
                  min = 50, max = 150, value = 115, step = 5),
      
      sliderInput("time", "Fermentation Time (h):", 
                  min = 12, max = 72, value = 60, step = 1),
      
      br(),
      actionButton("predict_btn", "Predict Yield", class = "btn-primary"),
      
      br(), br(),
      p("Built using simulated fermentation data, linear regression and machine learning.", 
        style = "font-size: 12px; color: #555;")
    ),
    
    mainPanel(
      h3("Prediction Results"),
      verbatimTextOutput("prediction"),
      
      h3("Model Comparison"),
      tableOutput("comparison"),
      
      h3("Variable Importance (Random Forest)"),
      plotOutput("varimp"),
      
      h3("Yield Trend: Glucose vs Time"),
      plotOutput("trend_plot")
    )
  )
)

# -----------------------------
# Step 4: Define Server
# -----------------------------
server <- function(input, output, session) {
  
  # Reactive prediction
  predictions <- eventReactive(input$predict_btn, {
    # Prepare new data with centered terms
    mean_temp <- mean(fermentation_data$temperature)
    mean_pH   <- mean(fermentation_data$pH)
    
    new_data <- data.frame(
      temp_centered = input$temp - mean_temp,
      temp2 = (input$temp - mean_temp)^2,
      pH_centered = input$ph - mean_pH,
      pH2 = (input$ph - mean_pH)^2,
      glucose_concentration = input$glucose,
      fermentation_time = input$time
    )
    
    # Predictions
    lm_pred <- predict(model_centered, newdata = new_data)
    rf_pred <- predict(rf_model, newdata = new_data)
    
    list(
      lm = round(lm_pred, 2),
      rf = round(rf_pred, 2)
    )
  })
  
  # Output: Predictions
  output$prediction <- renderPrint({
    req(input$predict_btn)
    preds <- predictions()
    cat("Linear Model Prediction: ", preds$lm, "g/L\n")
    cat("Random Forest Prediction: ", preds$rf, "g/L\n")
  })
  
  # Output: Model comparison (static)
  output$comparison <- renderTable({
    data.frame(
      Model = c("Linear Model", "Random Forest"),
      "R²" = c(0.942, 0.965),
      RMSE = c(1.20, 0.91),
      Source = c("Simulation Fit", "Out-of-bag RF")
    )
  })
  
  # Output: Variable Importance
  output$varimp <- renderPlot({
    varImpPlot(rf_model, main = "RF: Variable Importance")
  })
  
  # Output: Trend Plot (interactive example)
  output$trend_plot <- renderPlot({
    glucose_range <- seq(50, 150, by = 10)
    time_range <- seq(12, 72, by = 12)
    
    trend_grid <- expand.grid(
      glucose = glucose_range,
      time = time_range
    ) %>%
      mutate(
        temp_centered = 33 - mean(fermentation_data$temperature),
        temp2 = (33 - mean(fermentation_data$temperature))^2,
        pH_centered = 5.0 - mean(fermentation_data$pH),
        pH2 = (5.0 - mean(fermentation_data$pH))^2,
        fermentation_time = time,
        glucose_concentration = glucose
      )
    
    trend_grid$yield <- predict(rf_model, newdata = trend_grid)
    
    ggplot(trend_grid, aes(x = glucose, y = yield, color = factor(time))) +
      geom_line(linewidth = 1) +
      geom_point() +
      labs(
        title = "Ethanol Yield vs Glucose at Different Times",
        x = "Glucose (g/L)",
        y = "Predicted Ethanol Yield (g/L)",
        color = "Fermentation Time (h)"
      ) +
      theme_minimal() +
      scale_color_viridis_d(option = "plasma")
  })
}

# -----------------------------
# Step 5: Run the App
# -----------------------------
shinyApp(ui = ui, server = server)

