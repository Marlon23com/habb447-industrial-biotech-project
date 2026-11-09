# Load required libraries
library(tidyverse)

# Set seed for reproducibility
set.seed(11)

# Number of observations to simulate
n <- 500

# Simulate independent variables with realistic ranges
temperature     <- runif(n, min = 25, max = 40)         # °C
pH                <- runif(n, min = 4.0, max = 6.5)     # pH
glucose_concentration <- runif(n, min = 50, max = 150)  # g/L
fermentation_time <- runif(n, min = 12, max = 72)       # hours

# Pre-allocate ethanol_yield vector
ethanol_yield <- numeric(n)

# Define parameters based on biological knowledge of S. cerevisiae
for (i in 1:n) {
  # Maximum theoretical ethanol yield: ~0.51 g ethanol / g glucose
  # But real fermentation achieves ~85–90% of theoretical due to growth & maintenance
  theoretical_max_yield_per_g_glucose <- 0.51
  efficiency <- 0.85
  
  # Optimal temperature for S. cerevisiae: ~30–35°C
  # Use a Gaussian-like response around 32.5°C
  temp_opt <- 32.5
  temp_response <- dnorm(temperature[i], mean = temp_opt, sd = 3)
  temp_factor <- temp_response / dnorm(temp_opt, mean = temp_opt, sd = 3)  # normalized to 1 at peak
  
  # Optimal pH: ~4.5–5.5
  pH_opt <- 5.0
  pH_response <- dnorm(pH[i], mean = pH_opt, sd = 0.5)
  pH_factor <- pH_response / dnorm(pH_opt, mean = pH_opt, sd = 0.5)  # normalized
  
  # Time factor: fermentation increases with time but plateaus (~logistic growth)
  # Assume saturation after ~60 hours
  time_factor <- plogis(fermentation_time[i], location = 48, scale = 8)  # logistic curve
  time_factor <- time_factor / plogis(48, location = 48, scale = 8)  # normalize to ~1 at plateau
  
  # Glucose utilization: more glucose → more ethanol, but not linear due to inhibition
  # High glucose (>120 g/L) can cause osmotic stress → reduce efficiency
  glucose_factor <- ifelse(glucose_concentration[i] > 120,
                           1 - 0.3 * ((glucose_concentration[i] - 120) / 30),
                           1)
  glucose_factor <- pmax(glucose_factor, 0.6)  # avoid values too low
  
  # Base yield calculation
  base_yield <- (glucose_concentration[i] * 
                   theoretical_max_yield_per_g_glucose * 
                   efficiency * 
                   temp_factor * 
                   pH_factor * 
                   time_factor * 
                   glucose_factor)
  
  # Add random noise (biological variability + measurement error)
  noise <- rnorm(1, mean = 0, sd = 0.05 * base_yield)  # 5% relative error
  ethanol_yield[i] <- pmax(base_yield + noise, 0)  # ensure non-negative
}

# Combine into a data frame
fermentation_data <- tibble(
  temperature = round(temperature, 1),
  pH = round(pH, 2),
  glucose_concentration = round(glucose_concentration, 1),
  fermentation_time = round(fermentation_time, 1),
  ethanol_yield = round(ethanol_yield, 2)
)

# Display first few rows
head(fermentation_data)

# Summary statistics
summary(fermentation_data)

# Save to CSV
write_csv(fermentation_data, "simulated_fermentation_data.csv")


# Part 2: Data Visualization in R

# Load required library
library(ggplot2)
library(patchwork)  # For combining plots

# Set theme for all plots
theme_set(theme_minimal())

# Color palette for consistency
main_color <- "steelblue"

# Ethanol yield vs temperature

p1 <- ggplot(fermentation_data, aes(x = temperature, y = ethanol_yield)) +
  geom_point(aes(color = ethanol_yield), alpha = 0.7, size = 2) +
  scale_color_gradient(low = "yellow", high = "red", name = "Ethanol Yield") +
  geom_smooth(method = 'loess', se = TRUE, color = "darkblue", linewidth = 1) +
  labs(
    title = "Ethanol Yield vs. Temperature",
    x = "Temperature (°C)",
    y = "Ethanol Yield (g/L)",
    caption = "Color indicates yield level; trend shows optimal range near 32–35°C"
  ) +
  scale_x_continuous(breaks = seq(25, 40, by = 2))

p1

# Ethanol yield vs pH

p2 <- ggplot(fermentation_data, aes(x = pH, y = ethanol_yield)) +
  geom_point(aes(color = temperature), alpha = 0.6, size = 2) +
  scale_color_viridis_c(option = "plasma", name = "Temperature (°C)") +
  geom_smooth(method = 'loess', se = TRUE, color = "darkgreen", linewidth = 1) +
  labs(
    title = "Ethanol Yield vs. pH (Colored by Temperature)",
    x = "pH",
    y = "Ethanol Yield (g/L)",
    caption = "Yeast performs best near pH 4.5–5.5"
  )

p2

# Ethanol yield vs Glucose concentration (with pH Faceting)

# Enhanced Plot 3: Glucose vs Yield, with Size AND Color = Fermentation Time
p3_clean <- ggplot(fermentation_data, aes(x = glucose_concentration, y = ethanol_yield)) +
  geom_point(
    aes(size = fermentation_time, color = fermentation_time),
    alpha = 0.8
  ) +
  scale_size_area(max_size = 12, name = "Fermentation Time (h)") +
  scale_color_viridis_c(option = "plasma", name = "Fermentation Time (h)") +
  facet_wrap(~ pH_group, labeller = label_both) +
  geom_smooth(method = 'loess', se = TRUE, color = "white", linewidth = 1, alpha = 0.4) +
  labs(
    title = "Ethanol Yield vs. Glucose Concentration",
    subtitle = "Bubble size and color both indicate fermentation duration",
    x = "Glucose Concentration (g/L)",
    y = "Ethanol Yield (g/L)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 13, face = "bold"),
    panel.grid.major = element_line(linewidth = 0.3),
    panel.grid.minor = element_blank()
  )

p3_clean

# Ethanol yield vs Fermentation time (colored by glucose)

p4 <- ggplot(fermentation_data, aes(x = fermentation_time, y = ethanol_yield)) +
  geom_point(aes(color = glucose_concentration), alpha = 0.8, size = 2) +
  scale_color_gradient(low = "lightblue", high = "darkred", name = "Glucose (g/L)") +
  geom_smooth(method = 'loess', se = TRUE, color = "black", linewidth = 1) +
  labs(
    title = "Ethanol Yield Over Time (Colored by Initial Glucose)",
    x = "Fermentation Time (hours)",
    y = "Ethanol Yield (g/L)",
    caption = "Yield increases over time but plateaus around 60 hours"
  )

p4

# Heatmap-style: Mean Ethanol Yield by Temperature and pH (Faceted by Glucose Level)

library(tidyr)

# Recreate summarized data with complete grid
yield_summary <- fermentation_data %>%
  # Round for grouping (optional)
  mutate(
    temperature_bin = round(temperature / 0.5) * 0.5,  # bin every 0.5°C
    pH_bin = round(pH / 0.2) * 0.2                    # bin every 0.2 pH units
  ) %>%
  group_by(temperature_bin, pH_bin, glucose_level) %>%
  summarise(mean_yield = mean(ethanol_yield), .groups = "drop") %>%
  # Ensure all combinations exist (fill missing with NA)
  complete(temperature_bin, pH_bin, glucose_level) %>%
  # Clean up names
  rename(temperature = temperature_bin, pH = pH_bin)

# Now plot with tiles
p5 <- ggplot(yield_summary, aes(x = temperature, y = pH, fill = mean_yield)) +
  geom_tile(color = "white", linewidth = 0.1) +  # add light grid lines
  scale_fill_gradient(low = "lightyellow", high = "darkred", na.value = "white",
                      name = "Avg Ethanol Yield (g/L)") +
  facet_wrap(~ glucose_level, labeller = label_both) +
  labs(
    title = "Average Ethanol Yield by Temperature and pH",
    x = "Temperature (°C)",
    y = "pH"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    plot.background = element_rect(fill = "white")
  )

# Display plot
p5

# combine plots with patchwork 

# Arrange plots in layout
(p1 + p2) / (p3 + p4)




# ============================================================================== #

# install.packages("plotly")
library(plotly)

# Convert enhanced p3_clean to interactive
p3_interactive <- ggplotly(
  p3,
  tooltip = c("glucose_concentration", "ethanol_yield", "fermentation_time", "pH", "temperature")
)

# Show it
p3_interactive

# ============================================================================== #

# PART 3: STATISTICAL MODELING 

# Load libraries
library(broom)        # For tidy model summaries
library(car)          # For VIF (multicollinearity check)
library(DT)           # For interactive viewing
# install.packages('DT')

# Ensure required variables are in data
glimpse(fermentation_data)

# Fit a model with main effects + quadratic terms for temp and pH (expected nonlinear response)
model <- lm(
  ethanol_yield ~ 
    temperature + 
    I(temperature^2) + 
    pH + 
    I(pH^2) + 
    glucose_concentration + 
    fermentation_time,
  data = fermentation_data
)

# View model summary
summary(model)

# MOST INFLUENTIAL VARIABLES 

# Standardized regression coefficients

install.packages("QuantPsyc")
library(QuantPsyc)

# Fit model on standardized data
model_scaled <- lm(
  scale(ethanol_yield) ~ 
    scale(temperature) + 
    scale(I(temperature^2)) + 
    scale(pH) + 
    scale(I(pH^2)) + 
    scale(glucose_concentration) + 
    scale(fermentation_time),
  data = fermentation_data
)

# Get standardized coefficients (beta weights)
beta_coeffs <- lm.beta(model_scaled)
beta_coeffs

# Check multicollinearity
# VIF > 5 suggests multicollinearity.
# But this is expected for polynomial terms. Solution: center variables. 

vif(model)

# re center temp and pH before squaring

fermentation_data <- fermentation_data %>%
  mutate(
    temp_centered = temperature - mean(temperature),
    temp2 = temp_centered^2,
    pH_centered = pH - mean(pH),
    pH2 = pH_centered^2
  )

# Refit model with centered variables
model_centered <- lm(
  ethanol_yield ~ 
    temp_centered + temp2 + 
    pH_centered + pH2 + 
    glucose_concentration + 
    fermentation_time,
  data = fermentation_data
)

# Check VIF again
vif(model_centered)

summary(model_centered)

# Get standardized coefficients (beta weights)
beta_coeffs_centered <- lm.beta(model_centered)
beta_coeffs_centered


# PART 5: Machine learning with Random Forest

# Install
install.packages(c("randomForest", "Metrics"))

# Load libraries
library(randomForest)
library(caret)
library(Metrics)  # For easy RMSE/MAE
library(dplyr)
library(ggplot2)

# If not already done, create centered variables
fermentation_data <- fermentation_data %>%
  mutate(
    temp_centered = temperature - mean(temperature),
    temp2 = temp_centered^2,
    pH_centered = pH - mean(pH),
    pH2 = pH_centered^2
  )

# Select predictors (same as in linear model)
predictors <- c("temp_centered", "temp2", "pH_centered", "pH2",
                "glucose_concentration", "fermentation_time")

# Create clean dataset
ml_data <- fermentation_data %>%
  dplyr::select(all_of(predictors), ethanol_yield)

head(ml_data)

# Train Random Forest model

set.seed(123)  # For reproducibility

rf_model <- randomForest(
  ethanol_yield ~ .,
  data = ml_data,
  ntree = 500,      # Number of trees
  mtry = 3,         # Try different splits (default is fine)
  importance = TRUE # For variable analysis
)

# View model
print(rf_model)

# compare with linear model from centered data

# Linear model predictions (from centered model)
lm_pred <- predict(model_centered, newdata = fermentation_data)
rf_pred  <- predict(rf_model, newdata = ml_data)

# Actual values
actual <- fermentation_data$ethanol_yield

# Calculate metrics

# Function to compute metrics
get_metrics <- function(actual, pred, name) {
  data.frame(
    Model = name,
    RMSE = round(rmse(actual, pred), 3),
    MAE  = round(mae(actual, pred), 3),
    R2   = round(cor(actual, pred)^2, 3)
  )
}

# Compare
performance <- bind_rows(
  get_metrics(actual, lm_pred, "Linear Model"),
  get_metrics(actual, rf_pred, "Random Forest")
)

# Display
performance

# visualize predictions

# Combine for plotting
comparison <- tibble(
  actual = actual,
  linear = lm_pred,
  random_forest = rf_pred
) %>%
  pivot_longer(cols = c(linear, random_forest), names_to = "Model", values_to = "Predicted")

# Plot
ggplot(comparison, aes(x = actual, y = Predicted)) +
  geom_point(alpha = 0.6, size = 1.2) +
  geom_abline(intercept = 0, slope = 1, color = "red", linewidth = 1, linetype = "dashed") +
  facet_wrap(~ Model) +
  labs(
    title = "Actual vs Predicted Ethanol Yield",
    x = "Actual Yield (g/L)",
    y = "Predicted Yield (g/L)"
  ) +
  theme_minimal()
# the closer to the red line the better

# Variable importance 

# Importance plot
varImpPlot(rf_model, main = "Random Forest: Variable Importance")

# numbers
importance(rf_model)
