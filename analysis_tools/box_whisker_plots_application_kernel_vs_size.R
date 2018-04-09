
load('rundata.all.Rda')
library(ggplot2)

for(y in unique(rundata.all$application)){
    x <- subset(rundata.all, application == y)
    pdf(paste('../figures/application_vs_size_analysis/',y,'.pdf',sep=''))
    p <- ggplot(dat=x,aes(x=size,y=kernel_time,colour=kernel)) + geom_boxplot() + labs(x="Size",y=expression("Kernel Execution Time"~(mu*s)),colour="Kernel")
    print(p)
    dev.off()
}

for(y in unique(rundata.all$kernel)){
    x <- subset(rundata.all, kernel == y)
    pdf(paste('../figures/kernel_vs_size_analysis/',y,'.pdf',sep=''))
    p <- ggplot(dat=x,aes(x=size,y=kernel_time,colour=device)) + geom_boxplot() + labs(x="Size",y=expression("Kernel Execution Time"~(mu*s)),colour="Device")
    print(p)
    dev.off()
}
