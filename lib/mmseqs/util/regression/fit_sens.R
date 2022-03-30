#!/usr/bin/env Rscript
data <- read.table(file("stdin"))
colnames(data) <- c("s", "kthr", "roc")
fit <- lm(kthr ~ s, data=data)
df <- data.frame(s=c(1.0,3.0,5.0,5.7,6.0,7.0,8.5))
df$kthr <- floor(predict(fit, df))
fit$coefficients
df

if (0) {
library(ggplot2)
library(cowplot)
ggplot(data, aes(s, kthr)) +
    geom_point() +
    stat_smooth(formula = y ~ x, method = "lm", col = "red", fullrange=TRUE) +
    xlim(0,10) +
    theme_cowplot()
}
