library(ggplot2)
library(cowplot)
library(reshape2)

source("load_data.R")

#generates boxplots of relative execution times
print("generating boxplots...")

applications <- c('kmeans')

#generate a plot for each application with all 4 sizes
for(application in applications){
    print(paste("saving ",application,"...",sep=''))
    pdf(paste('cache_misses_',application,'.pdf',sep=''))
    for(size in sizes){
        #pdf(paste(application,'_',size,'.pdf',sep=''))
        x <- data.cache[data.cache$application == application & data.cache$size == size,]
        p <- ggplot(x, aes(x=cache_level,y=misses)) +
            geom_boxplot(outlier.alpha = 0.1,varwidth=TRUE)+
            ylab('miss count (ms)') + xlab('cache level')#+ 
            #scale_x_discrete(breaks=seq(5,47,by=1))+
            #scale_y_continuous(limit = c(0, max(x$time*0.001)*1.05)) +
            #theme(axis.text.x = element_text(angle = 45, hjust = 1))
        #print(p)
        #dev.off()
        assign(paste("plot.",size,sep=""),p)
    }
    print(plot_grid(plot.tiny,plot.small,plot.medium,plot.large,labels="AUTO",hjust=-1,vjust=1))#,scale=c(.1,.1,.9,.9)))
    dev.off()
}
