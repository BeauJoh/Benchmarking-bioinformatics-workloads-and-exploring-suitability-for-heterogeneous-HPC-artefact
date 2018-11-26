"%!in%" <- Negate("%in%")
library(ggplot2)
library(cowplot)
library(plyr)
library(viridis)

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
data.all$device <- factor(data.all$device,levels=levels(data.all$device)[c(1,2,12,3,4,5,6,7,15,14,10,11,9,13,8)])

#attach accelerator type
device_index <- c("i7-6700K",
                  "E5-2697",
                  "i5-3550",
                  "Titan X",
                  "GTX 1080",
                  "GTX 1080 Ti",
                  "K20m",
                  "K40m",
                  "HD 7970",
                  "R9 290X",
                  "R9 295x2",
                  "FirePro S9150",
                  "R9 Fury X",
                  "RX 480",
                  "Xeon Phi 7210")
accelerator_type <- c("CPU",#"i7-6700K" #"Desktop CPU"
                      "CPU",#"E5-2697"   #"Server CPU"
                      "CPU",#"i5-3550"  #"Desktop CPU"
                      "Consumer GPU",#"Titan X"
                      "Consumer GPU",#"GTX 1080"
                      "Consumer GPU",#"GTX 1080 Ti"
                      "HPC GPU",#"K20m"
                      "HPC GPU",#"K40m"
                      "Consumer GPU",#"HD 7970"
                      "Consumer GPU",#"R9 290X"
                      "Consumer GPU",#"R9 295x2"
                      "HPC GPU",#"FirePro S9150"
                      "Consumer GPU",#"R9 Fury X"
                      "Consumer GPU",#"RX 480"
                      "MIC")#"Xeon Phi 7210"
data.all$accelerator_type <- accelerator_type[match(data.all$device,device_index)]
data.all$accelerator_type <- factor(data.all$accelerator_type,
                                    levels=c("CPU","Consumer GPU","HPC GPU","MIC"))

if(!exists("single.figures")){
drop_phi = FALSE
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
                  "nw",
                  "gem",
                  "nqueens",
                  "hmm")
sizes <- c('tiny','small','medium','large')

#generate a plot for each application with all 4 sizes
for(a in applications){
    print(paste("saving ",a,"...",sep=''))
    for(s in sizes){
        #don't generate plots for these medium and large sized problems for these applications
        if(a %in% c("gem","nqueens","hmm") & s %in% c("medium","large")){
            next
        }

        pdf(paste('../figures/full_bandw_sep/',a,"_",s,'.pdf',sep=''))
        x <- data.all[data.all$application == a & data.all$size == s,]

        #drop phi except for listed applications
        if(drop_phi & a %!in% c("crc")){
            x <- subset(x,device != "Xeon Phi 7210")
        }

        p <- ggplot(x, aes(x=factor(device), y=total_time*0.001,colour=accelerator_type)) +
            geom_boxplot(outlier.alpha = 0.1,varwidth=TRUE)+
            labs(colour="accelerator type",y='time (ms)',x='')+
            scale_y_continuous(limit = c(0, max(x$total_time*0.001)*1.05)) +
            scale_color_viridis(discrete=TRUE) + theme_bw() + 
            theme(axis.text.x = element_text(size=10, angle = 45, hjust = 1),
                  title = element_text(size=10, face="bold"),
                  plot.margin = unit(c(0,0,0,0), "cm"))

        #just adjust the size-title since the application row title sits over the top of them
        s_title <- s
        if(s == 'tiny' && a == 'kmeans'){
            s_title <- '                         tiny'
        }
        if(s == 'tiny' && a == 'fft'){
            s_title <- '                   tiny'
        }

        #only include "size" as a title on these applications
        if(a %in% c("crc","kmeans","fft")){
            p <- p + ggtitle(s_title)
        }

        print(p)
        dev.off()
        assign(paste("plot.",a,".",s,sep=""),p)
    }
}
single.figures <- data.frame()
}
legends <- get_legend(plot.crc.tiny)+theme(legend.title=element_text(face="bold"),
                                           legend.position="top",
                                           legend.justification="left")

#csr -- just show small and large

#crc results
print("saving generate_sample_csr_row_bandwplot.pdf")
csr_row <- plot_grid(plot.csr.small  +theme(legend.position = "none")+ ggtitle("small"),
                     plot.csr.large +theme(legend.position = "none")+ ggtitle("large"),
                     ncol=2,nrow=1)
legend_csr <- get_legend(plot.csr.small + theme(legend.title=element_text(face="bold"),
                                             legend.position="bottom",legend.justification="right"))#"center"))
p <- plot_grid(csr_row, legend_csr, ncol = 1, rel_heights = c(1, .05))
pdf('./generate_sample_csr_row_bandwplot.pdf',width=7,height=4)
print(p)
dev.off()

