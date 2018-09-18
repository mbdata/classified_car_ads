set.seed(42)
library(ggplot2)
library(reshape2)
library(plyr)
library(readr)
library(fpc)
library(data.table)
library(knitr)
library(kableExtra)

#read data into a dataframe; need to change path
output_1 <- read.delim("~/Portfolio/classified_car_ads/data/output_1", header=FALSE)

column_names = c("Maker","Model","Mileage","Manufacture_Year","Engine_Displacement","Engine_Power","Body_Type","Color_Slug","STK_Year","Transmission","Door_Count","Seat_Count","Fuel_Type","Date_Created","Date_Last_Seen","Price_Eur"
)
names(output_1) = column_names
View(head(output_1))

output_1$ListedTS <- strptime(output_1$Date_Created, '%Y-%m-%d %H:%M:%OS')
output_1$RemovedTS <- strptime(output_1$Date_Last_Seen, '%Y-%m-%d %H:%M:%OS')

output_1$DaysListed <- as.integer(ceiling(
  difftime(output_1$RemovedTS, output_1$ListedTS, units = "days")))

output_1$Age <- as.integer(ceiling(
  difftime(output_1$ListedTS, strptime(output_1$Manufacture_Year,'%Y'), units = "days")/365))

#the proportions of the number of days various cars are listed for sale
ggplot(output_1, aes(x=DaysListed)) + 
  geom_density(fill="#FF6666", alpha=.1) +
  geom_vline(aes(xintercept=42), color="blue", linetype="dashed", size=1) +
  geom_vline(aes(xintercept=60), color="red", linetype="dashed", size=1)

#let's assume that a car listed for less than 42 days has been sold
output_1$Sold <- output_1$DaysListed <= 42

#what is the distribution of ages of the cars?
ggplot(output_1, aes(x=Age)) + 
  geom_density(fill="#FF6666", alpha=.1) +
  scale_x_continuous(limits = c(0, 30))+
  geom_vline(aes(xintercept=mean(Age, na.rm=T)),
             color="green", linetype="dashed", size=1)

#view first 10 rows with bootstrap-themed dataframe
head(output_1) %>%
  kable() %>%
  kable_styling()

#What are the most advertised vs most sold cars brands?
require(forcats)
total = nrow(output_1)
ggplot(output_1, aes(fct_rev(fct_infreq(Maker)), fill=Sold)) +
  geom_bar() +
  labs(x="", y="Percent of Ads") +
  scale_y_continuous(labels = function(x) sprintf("%.0f%%",x/total*100)) +
  coord_flip()

#what are the most advertised vs most sold models?
require(forcats)
total <- nrow(cars.sample)
output_1$Car <- paste(output_1$Maker, output_1$Model)
betsCarsList <- fct_infreq(output_1$Car)
output_1.bestCars <- output_1[output_1$Car %in%  levels(betsCarsList)[1:20],]
ggplot(output_1.bestCars, aes(fct_rev(fct_infreq(Car)), fill=Sold)) +
  geom_bar() + 
  labs(x="", y="Percent of Ads in the Sample Set") +
  scale_y_continuous(labels = function(x) sprintf("%.0f%%",x/total*100)) + 
  coord_flip()

#distribution of the prices of cars that remained unsold
ggplot(output_1[!(output_1$Sold),], aes(x=Price_Eur)) + 
  geom_density(fill="#FF6666", alpha=.1) +
  scale_x_continuous(limits = c(0, 80000)) +
  geom_vline(aes(xintercept=mean(Price_Eur, na.rm=T)), color="red", linetype="dashed", size=1)

#distribution of car prices for cars that were sold
ggplot(output_1[output_1$Sold,], aes(x=Price_Eur)) + 
  geom_density(fill="#FF6666", alpha=.1) +
  scale_x_continuous(limits = c(0, 80000)) +
  geom_vline(aes(xintercept=mean(Price_Eur, na.rm=T)), color="red", linetype="dashed", size=1)

We can see that premium brands, such as Bentley, Lamborghini, and Tesla, have cars that are priced above most other brands. In order to filter out the instances of non-premium cars that are priced highly due to error, I will create an outlier removal function that creates a boxplot with an interquartile range and whiskers, and, when applied to a selected brand, will delete all instances above and below the whiskers.

```{r}
#initialize function that takes a vector of prices calculates the interquartile range and whiskers (1.5*IQR) above and below it, and removes all the points beyond the whiskers.
remove_outliers <- function(x, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
  H <- 1.5 * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H*3)] <- NA
  y[x > (qnt[2] + H*3)] <- NA
  y
}
```

Let's apply this outlier removal function to a brand that has one row in the dataset with a car priced at 1M Euro, Citroen. For simplicity I will create a subset of data consisting only of car prices belonging to Citroen and then feed this vector to the function. I made sure to extend the top whisker to include the instance where the car is priced at about 50,000 Euro, since this is not a mistake, and so it will not be deleted.

```{r}
#example of outlier removal for Citroen, before...
cit_price = data[data$Maker == 'citroen', "Price_Eur"]
boxplot(cit_price)
#...and after
cit_price <- remove_outliers(cit_price)
boxplot(cit_price)
```

After removing the outlier seen in the first boxplot, the range of prices for Citroen now appears to be normal (and still includes the car priced at 50,000 Euro). We will apply the same treatment to another brand, BMW, which I saw has a car listed for over 100M Euro. However, we need to be careful that we do not delete the instances of BMW cars that are highly but correctly priced, since BMW does in fact sell such cars (ex. BMW M6). We can do this by modifying the length of the whisker in the function to be, say, ten times that of the original, so that it includes these more expensive cars and prevents them from being removed. Only the instances above (and below) the whisker will be deleted.

```{r}
#create a vector of all BMW prices
bmw = data[data$Maker == "bmw", "Price_Eur"]
boxplot(bmw)

#remove outliers for bmw
remove_outliers_bmw = function(x, na.rm = TRUE, ...) {
qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
H <- 1.5 * IQR(x, na.rm = na.rm)
y <- x
y[x < (qnt[1] - H*10)] <- NA
y[x > (qnt[2] + H*10)] <- NA
y
}

bmw = remove_outliers_bmw(bmw)
boxplot(bmw)
```
Now, the range of BMW prices appears to be normal. We should apply this function to all of those brands with prices that exist due to error. This means that we need to examine the brands one by one, or, alternatively, create a looping function that takes dynamic argument lists that let us modify the length of the whisker, so that we do not delete instances of highly but correctly priced cars.

