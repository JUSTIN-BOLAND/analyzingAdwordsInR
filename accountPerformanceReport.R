##Loop through all of these accounts and get the information you need

library(RAdwords)
library(dplyr)
library(reshape2)
library(ggplot2)

#Read in a list of clients. This data will need to be exported on the MCC level. 
clients <- read.csv("clients.csv", header = TRUE, sep = ",")

#Client ID's to account for looping
accounts = as.vector(clients$Customer.ID)

# Authentication, once done you can access all accounts in your MCC
google_auth <- doAuth()

# Specify date range, i.e. last two weeks until yesterday
yesterday <- gsub("-", "", format(Sys.Date()-1,"%Y-%m-%d"))
thirtydays<- gsub("-", "", format(Sys.Date()-29,"%Y-%m-%d"))

# Create statement
body <- statement(select=c("AccountDescriptiveName",
                           "Impressions",
                           "Clicks",
                           "Ctr", 
                           "Conversions",
                           "AverageCpc", 
                           "Cost", 
                           "CostPerConvertedClick",
                           "Date"),
                  report="ACCOUNT_PERFORMANCE_REPORT",
                  where="AdNetworkType1 = SEARCH",
                  start=thirtydays,
                  end=yesterday)

#Test if needed
#   data <- getData(clientCustomerId='xxx-xxx-xxxx', google_auth=google_auth ,statement=body)

#Loop over accounts and rbind data to dataframe
loopData <- function(){
  for(i in 1:length(accounts)){
    if (i == 1){
      xy <- getData(clientCustomerId=accounts[i],statement=body,google_auth = google_auth,transformation=TRUE,changeNames=TRUE)
    }
    else {
      xz <- getData(clientCustomerId=accounts[i],statement=body,google_auth = google_auth,transformation=TRUE,changeNames=TRUE)
      xy <- rbind(xy,xz)
    }
  }
  return(xy)
}
data <- loopData()
data$CPO <- round(data$CPO,2)
data$CPC <- round(data$CPC,2)
data <- data[order(-data$Impressions),] 
row.names(data) = NULL
View(data)

# ---- Regression Work ---- 
#Linear Regression
lm(Clicks ~ Conversions)

#Find the coefficient of determination for the simple linear regression model of the data set
lm.out = lm(Clicks ~ Conversions)
summary(lm.out)$r.squared

options(show.signif.stars=F)
anova(lm.out)

plot(Clicks ~ Conversions, main="Cost & Conversions")
abline(lm.out, col="red")

# --- Daily Performance reports ---
data2 <- data %>% 
  group_by(day = Day) %>% 
  summarize(cpc = mean(CPC),
            impressions = sum(Impressions))

data1 = data
data1$Account = NULL
data1$Impressions = NULL

data3 <- melt(data1, id="day")

data2 %>%
ggplot(aes(day, cpc, Impressions)) + 
  geom_line(aes(fill = cpc , size = .75) + 
  theme(legend.position = "none") 

ggplot(data3, aes(day, value, variable)) + 
  geom_line()
