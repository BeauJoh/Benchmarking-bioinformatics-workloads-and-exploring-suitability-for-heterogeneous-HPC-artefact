library(ggplot2)

source("load_data.R")

library(reshape)

## repeat random selection
set.seed(1)
 
result_matrix <- matrix(nrow = length(devices),ncol=1)
for(device in devices){
    x <- data.kmeans[data.kmeans$region=="kmeans_kernel" & data.kmeans$device == device & data.kmeans$size == "tiny",]
    #divide x into a partial sum of each run (the #of iterations till convergence) 0-11, then store that mean
    times <- colSums(matrix(x$time, nrow=12))
    result_matrix[which(devices == device),1] <- median(times)
}


 
## set color representation for specific values of the data distribution
quantile_range <- quantile(result_matrix, probs = seq(0, 1, 0.2))
 
## use http://colorbrewer2.org/ to find optimal divergent color palette (or set own)
color_palette <- colorRampPalette(c("#3794bf", "#FFFFFF", "#df8640"))(length(quantile_range) - 1)
 
## prepare label text (use two adjacent values for range text)
label_text <- rollapply(round(quantile_range, 2), width = 2, by = 1, FUN = function(i) paste(i, collapse = " : "))
 
## discretize matrix; this is the most important step, where for each value we find category of predefined ranges (modify probs argument of quantile to detail the colors)
mod_mat <- matrix(findInterval(result_matrix, quantile_range, all.inside = TRUE), nrow = nrow(result_matrix))
 
## remove background and axis from plot
theme_change <- theme(
 plot.background = element_blank(),
 panel.grid.minor = element_blank(),
 panel.grid.major = element_blank(),
 panel.background = element_blank(),
 panel.border = element_blank()
 #axis.line = element_blank(),
 #axis.ticks = element_blank(),
 #axis.text.x = element_blank(),
 #axis.text.y = element_blank(),
 #axis.title.x = element_blank(),
 #axis.title.y = element_blank()
)
 
## output the graphics
x <- ggplot(melt(mod_mat), aes(x = X1, y = X2, fill = factor(value))) +
    geom_tile(color = "black") +
    scale_fill_manual(values = color_palette, name = "", labels = label_text) +
    theme_change
ggsave("heatmap.pdf",x)

