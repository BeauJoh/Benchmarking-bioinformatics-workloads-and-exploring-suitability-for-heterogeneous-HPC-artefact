source("utils.R")
source("stats.R")
source("aes.R")
source("functions.R")

if (!exists("data.resolution")){
    columns <- c('id','time','overhead')
    data.resolution <- ReadAllFilesInDir.Aggregate('./lsb_resolution_data/',col=columns)
}

p <- ggplot(data.resolution, aes(time)) + geom_histogram(binwidth=0.0000116) + xlim(0.005, 0.0125) + xlab("time (ns)")

pdf('lsb_timer_resolution_histogram.pdf')
print(p)
dev.off()
