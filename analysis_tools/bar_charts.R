library(ggplot2)
library(cowplot)
library(plyr)

#source("load_data.R")
load('rundata.all.Rda')
data.all <- rundata.all

#rename devices
data.all$device <- revalue(data.all$device,
                           c("xeon_es-2697v2"="E5-2697",
                             "i7-6700k"="i7-6700K",
                             "i5-3350"="i5-3550",
                             "titanx"="Titan X",
                             "gtx1080"="GTX 1080",
                             "gtx1080ti"="GTX 1080 Ti",
                             "k20c"="K20m",
                             "k40c"="K40m",
                             "knl"="Xeon Phi 7210",
                             "fiji-furyx"="R9 Fury X",
                             "hawaii-r9-290x"="R9 290X",
                             "hawaii-r9-295x2"="R9 295x2",
                             "polaris-rx480"="RX 480",
                             "tahiti-hd7970"="HD 7970",
                             "firepro-s9150"="FirePro S9150"
                             ))
#reorder devices
data.all$device = factor(data.all$device,levels(data.all$device)[c(1,2,12,3,4,5,6,7,14,10,11,15,9,13,8)])

#generates boxplots of relative execution times
print("generating boxplots...")

applications <- c("kmeans",
                  "lud",
                  "csr",
                  "fft",
                  "dwt",
                  "srad",
                  "crc",
                  "bfs",
                  "nw")
sizes <- c('tiny','small','medium','large')

#applications <- c('kmeans','lud','csr','fft','dwt','gem','srad','crc')

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
    pdf(paste('../figures/full_bandw/',application,'.pdf',sep=''))
    for(size in sizes){
        #pdf(paste(application,'_',size,'.pdf',sep=''))
        x <- data.all[data.all$application == application & data.all$size == size,]
        p <- ggplot(x, aes(x=factor(device), y=kernel_time*0.001)) +
            geom_boxplot(outlier.alpha = 0.1,varwidth=TRUE)+
            ylab('time (ms)') + xlab('') + 
            #scale_x_discrete(breaks=seq(5,47,by=1))+
            scale_y_continuous(limit = c(0, max(x$kernel_time*0.001)*1.05)) +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
        #print(p)
        #dev.off()
        assign(paste("plot.",size,sep=""),p)
    }
    print(plot_grid(plot.tiny,plot.small,plot.medium,plot.large,labels="AUTO",hjust=-1,vjust=1))#,scale=c(.1,.1,.9,.9)))
    dev.off()
}
