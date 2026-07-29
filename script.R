# Load the required packages for time series analysis and VAR estimation
install.packages("tseries")
install.packages("vars")
library(tseries)
library(vars)

# Import the dataset 
my_dataset <-read.csv(file.choose())
head(my_dataset)

# Compute the log-difference of energy prices
my_dataset$log_energy <- c (NA, 100 * diff(log(my_dataset$Energy))) # Multiplied by 100 to convert to % growth rate
head(my_dataset[, c("Date", "Energy", "log_energy")])

my_dataset$log_energy[is.na(my_dataset$log_energy)] <- 0.1258661 # I replaced the missing value in log_energy column with 0.1258661, which I calculated manually.
head(my_dataset[, c("Date", "Energy", "log_energy")])

# Now I run the ADF test for each variables in my dataframe 
adf.test(my_dataset$Policy_Rate)
adf.test(my_dataset$CPI_Trim)
adf.test(my_dataset$Total_CPI)
adf.test(my_dataset$log_energy)

ts_data <- ts(my_dataset[, c("log_energy", "Total_CPI", "CPI_Trim", "Policy_Rate")], start = c(1999,1), frequency = 12)
plot(ts_data)

# Construct the final dataset used in the VAR estimation
Dataset <- data.frame( 
+     Date = my_dataset$Date[-1], # Drops first row to align with diff()
+     Energy_prices  = my_dataset$log_energy[-1],
+     Headline_inflation = my_dataset$Total_CPI[-1],
+     Core_Inflation = diff(my_dataset$CPI_Trim),
+     Policy_rate  = diff(my_dataset$Policy_Rate))
adf.test(Dataset$Core_Inflation)
adf.test(Dataset$Policy_rate)
VAR_data <- Dataset[, -1]

# Select the optimal lag length using standard information criteria
lagselect <- VARselect(VAR_data,lag.max = 8, type = "const")
lagselect

# Estimate the VAR model with the selected lag order
var_model <- VAR(VAR_data, p = 3, type = "const")
summary(var_model)
roots(var_model)

# Compute IRF and FEDV
IRFs <- irf(var_model, impulse = "Energy_prices", response = c("Headline_inflation", "Core_Inflation", "Policy_rate"), n.ahead = 20, boot = TRUE, ci = 0.95)
plot(IRFs)
FEVD <- fevd(var_model, n.ahead = 20)
plot(FEVD)
