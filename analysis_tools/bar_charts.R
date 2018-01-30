library(ggplot2)
library(cowplot)

source("load_data.R")

#generates boxplots of relative execution times
print("generating boxplots...")

applications <- c('kmeans','lud','csr','fft','dwt','gem','srad','crc')

#for(application in applications){
#    for(size in sizes){
#        print(paste("saving ",application,"_",size,"...",sep=''))
#        pdf(paste('./figures',application,'_',size,'.pdf',sep=''))
#        x <- data.all[data.all$application == application & data.all$size == size,]
#        p <- ggplot(x, aes(x=factor(device), y=time*0.001)) +
#            geom_boxplot(outlier.alpha = 0.1,varwidth=TRUE)+
#            ylab('time (ms)') + xlab('device') + 
#            theme(axis.text.x = element_text(angle = 45, hjust = 1))
#        print(p)
#        dev.off()
#    }
#}

#generate a plot for each application with all 4 sizes
for(application in applications){
    print(paste("saving ",application,"...",sep=''))
    pdf(paste('./figures/',application,'.pdf',sep=''))
    for(size in sizes){
        #pdf(paste(application,'_',size,'.pdf',sep=''))
        x <- data.all[data.all$application == application & data.all$size == size,]
        p <- ggplot(x, aes(x=factor(device), y=time*0.001)) +
            geom_boxplot(outlier.alpha = 0.1,varwidth=TRUE)+
            ylab('time (ms)') + xlab('') + 
            #scale_x_discrete(breaks=seq(5,47,by=1))+
            scale_y_continuous(limit = c(0, max(x$time*0.001)*1.05)) +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
        #print(p)
        #dev.off()
        assign(paste("plot.",size,sep=""),p)
    }
    print(plot_grid(plot.tiny,plot.small,plot.medium,plot.large,labels="AUTO",hjust=-1,vjust=1))#,scale=c(.1,.1,.9,.9)))
    dev.off()
}
