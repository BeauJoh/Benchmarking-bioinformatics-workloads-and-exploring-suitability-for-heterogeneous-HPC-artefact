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
drop_phi = TRUE
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

#crc results
print("saving crc_row_bandwplot.pdf")
crc_row <- plot_grid(plot.crc.tiny  +theme(legend.position = "none"),
                     plot.crc.small +theme(legend.position = "none"),
                     plot.crc.medium+theme(legend.position = "none"),
                     plot.crc.large +theme(legend.position = "none"),
                     ncol=4,nrow=1)
legend_crc <- get_legend(plot.crc.tiny + theme(legend.title=element_text(face="bold"),
                                             legend.position="bottom",legend.justification="right"))#"center"))
p <- plot_grid(crc_row, legend_crc, ncol = 1, rel_heights = c(1, .05))
pdf('../figures/new-time-results/generate_crc_row_bandwplot.pdf',width=13,height=4)
print(p)
dev.off()

#4x4 results
print("saving main_4x5_bandwplot.pdf")
legend_generic <- get_legend(plot.kmeans.tiny + theme(legend.title=element_text(face="bold"),
                                                      legend.position="bottom",legend.justification="right"))

plots <- align_plots(plot.kmeans.tiny  +theme(legend.position = "none"),
                     plot.kmeans.small +theme(legend.position = "none"),
                     plot.kmeans.medium+theme(legend.position = "none"),
                     plot.kmeans.large +theme(legend.position = "none"),
                     plot.lud.tiny  +theme(legend.position = "none"),
                     plot.lud.small +theme(legend.position = "none"),
                     plot.lud.medium+theme(legend.position = "none"),
                     plot.lud.large +theme(legend.position = "none"),
                     plot.csr.tiny  +theme(legend.position = "none"),
                     plot.csr.small +theme(legend.position = "none"),
                     plot.csr.medium+theme(legend.position = "none"),
                     plot.csr.large +theme(legend.position = "none"),
                     plot.dwt.tiny  +theme(legend.position = "none"),
                     plot.dwt.small +theme(legend.position = "none"),
                     plot.dwt.medium+theme(legend.position = "none"),
                     plot.dwt.large +theme(legend.position = "none"),
                     plot.fft.tiny  +theme(legend.position = "none"),
                     plot.fft.small +theme(legend.position = "none"),
                     plot.fft.medium+theme(legend.position = "none"),
                     plot.fft.large +theme(legend.position = "none"),
                     align='v',axis='l')

kmeans_row <- plot_grid(plots[[1]], plots[[2]], plots[[3]], plots[[4]], ncol=4,nrow=1)
lud_row    <- plot_grid(plots[[5]], plots[[6]], plots[[7]], plots[[8]], ncol=4,nrow=1)
csr_row    <- plot_grid(plots[[9]], plots[[10]],plots[[11]],plots[[12]],ncol=4,nrow=1)
dwt_row    <- plot_grid(plots[[13]],plots[[14]],plots[[15]],plots[[16]],ncol=4,nrow=1)
fft_row    <- plot_grid(plots[[17]],plots[[18]],plots[[19]],plots[[20]],ncol=4,nrow=1)

p <- plot_grid(kmeans_row,lud_row,csr_row,dwt_row,#fft_row,#add plots
               legend_generic,#add legend
               ncol = 1, nrow = 5,#specify layout
               labels = c("(a) kmeans","(b) lud","(c) csr", "(d) dwt"),
               label_x = c(.001,.013,.013,.01), #adjust x offset of each row label
               label_y = c(1.0,1.06,1.06,1.06), #adjust y offset of each row label
               rel_heights=c(1,1,1,1,.05))#the legend needs much less space

pdf('../figures/new-time-results/generate_main_4x5_bandwplot.pdf',width=16.6,height=18.72)
print(ggdraw(p))
dev.off()


#remainder 4x2 results
print("saving main_4x2_bandwplot.pdf")
plots <- align_plots(plot.srad.tiny  +theme(legend.position = "none"),
                     plot.srad.small +theme(legend.position = "none"),
                     plot.srad.medium+theme(legend.position = "none"),
                     plot.srad.large +theme(legend.position = "none"),
                     plot.nw.tiny  +theme(legend.position = "none"),
                     plot.nw.small +theme(legend.position = "none"),
                     plot.nw.medium+theme(legend.position = "none"),
                     plot.nw.large +theme(legend.position = "none"),
                     align='v',axis='l')

srad_row  <- plot_grid(plots[[1]], plots[[2]], plots[[3]], plots[[4]], ncol=4,nrow=1)
nw_row    <- plot_grid(plots[[5]], plots[[6]], plots[[7]], plots[[8]], ncol=4,nrow=1)

p <- plot_grid(fft_row,srad_row,nw_row,#add plots
               legend_generic,#add legend
               ncol = 1, nrow = 4,#specify layout
               labels = c("(a) fft","(b) srad","(c) nw"),
               label_x = c(.015,.01,.012), #adjust x offset of each row label
               label_y = c(1.0,1.06, 1.06), #adjust y offset of each row label
               rel_heights=c(1,1,1,.05))#the legend needs much less space

pdf('../figures/new-time-results/generate_main_4x2_bandwplot.pdf',width=16.6,height=14.04)
print(ggdraw(p))
dev.off()


#2x3 results
#gem, nqueens and hmm only runs on tiny and small problem sizes
print("saving main_2x3_bandwplot.pdf")
plots <- align_plots(plot.gem.tiny + ggtitle("(a) gem")  +theme(legend.position = "none"),
                     #plot.gem.small +theme(legend.position = "none"),
                     plot.nqueens.tiny+ ggtitle("(b) nqueens")  +theme(legend.position = "none"),
                     #plot.nqueens.small +theme(legend.position = "none"),
                     plot.hmm.tiny + ggtitle("(c) hmm") +theme(legend.position = "none"),
                     #plot.hmm.small +theme(legend.position = "none"),
                     align='v',axis='l')

p <- plot_grid(plots[[1]], plots[[2]], plots[[3]],
               get_legend(plot.kmeans.tiny + theme(legend.title=element_text(face="bold"))),#add legend
               ncol=4,nrow=1,#specify layout
               rel_widths=c(0.3,0.3,0.3,0.1))#the legend needs much less space

               #label_x = c(.01,.0,0.01), #adjust x offset of each row label
               #label_y = c(1.0 ,1.06,1.06), #adjust y offset of each row label

pdf('../figures/new-time-results/generate_main_2x3_bandwplot.pdf',width=16.6,height=4.7)
print(ggdraw(p))
dev.off()

