#!/usr/bin/env Rscript

library(ggplot2)

source("utils.R")
source("stats.R")
source("aes.R")
source("functions.R")

SAMPLE_LIBRARY <- FALSE
LOAD_DATA <- FALSE
PLOT_DENSITY <- FALSE
PLOT_ENERGY_SCALING <- FALSE
PLOT_L1_SCALING <- FALSE
PLOT_L2_SCALING <- FALSE
PLOT_L3_SCALING <- TRUE

#performance_measurements = c('energy_nanojoules')
#                             'L1_data_cache_miss_rate',
#                             'L2_data_cache_miss_rate',
#                             'L3_total_cache_miss_rate')

performance_measurements = c('time',
                             'instructions_per_cycle',
#                             'L1_data_cache_request_rate',
                             'L1_data_cache_miss_rate',
#                             'L1_data_cache_miss_ratio',
                             'L2_data_cache_request_rate',
                             'L2_data_cache_miss_rate',
                             'L2_data_cache_miss_ratio',
                             'L3_total_cache_request_rate',
                             'L3_total_cache_miss_rate',
                             'L3_total_cache_miss_ratio',
                             'data_translation_lookaside_buffer_miss_rate',
                             'branch_rate',
                             'branch_misprediction_rate',
                             'branch_misprediction_ratio',
                             'energy_nanojoules')

if(SAMPLE_LIBRARY){#example of how to use the library
    data.test_study <-  ReadAllFilesInDir.Aggregate(dir.path="test_data/", col=c("size", "region", "id", "time", "overhead"))
    data.test_summary <- CalculateDataSummary(data=data.test_study, measurevar="time", groupvars=c("region"), conf.interval=.95, quantile.interval=.95)
    data.shapiro <- lsb_shapiro(data.test_study,'time')
    data.density <- lsb_density(data.test_study,'time','Time (us)')
    data.qq <- lsb_qqplot(data.test_study,'time')
    #data.box <- lsb_boxplot(data.test_study,aes(factor(eval(parse(text='time'))), eval(parse(text='size'))),"Time (us)","Density")
    #data.violin <- lsb_violinplot(data.test_study,aes(factor(eval(parse(text='time'))), eval(parse(text='size'))),"Time (us)","Density")
    pdf('density.pdf')
    print(data.density)
    dev.off()
    pdf('qq.pdf')
    print(data.qq)
    dev.off()
    #pdf('box.pdf')
    #print(data.box)
    #dev.off()
    #pdf('violin.pdf')
    #print(data.violin)
    #dev.off()
}

#Real analysis: Is the distribution normal?
#this data is with dynamic frequency scaling
#data.raw <- ReadAllFilesInDir.Aggregate(
#        dir.path="./find_problem_sizes_kmeans/kmeans_default_L1_cache.0/",
#        col=c("region","number_of_objects","number_of_features",
#              "iteration_number_hint_until_convergence","id","time","overhead",
#              "PAPI_L1_DCA","PAPI_L1_DCM"))

#for (i in seq(1,length(data.by_region))){
#    region <- data.by_region[[i]]
#    region_name <- paste(unique(region$region),"_time.pdf",sep='')
#    printf("Generating Density plot: %s\n",region_name)
#    pdf(region_name)
#    print(lsb_density(region,'time','Time (us)'))
#    dev.off()
#}

all_kmeans_columns <- c("region","number_of_objects","number_of_features",
                        "iteration_number_hint_until_convergence","id", "time","overhead")

papi_event_columns.time <- append(all_kmeans_columns,c("NA","NA"))
papi_event_columns.instructions_per_cycle            <-
    append(all_kmeans_columns,c("PAPI_TOT_CYC","PAPI_TOT_INS"))
papi_event_columns.L1_data_cache_request_rate        <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_L1_DCA"))
papi_event_columns.L1_data_cache_miss_rate           <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_L1_DCM"))
papi_event_columns.L1_data_cache_miss_ratio          <-
    append(all_kmeans_columns,c("PAPI_L1_DCA","PAPI_L1_DCM"))
papi_event_columns.L2_data_cache_request_rate        <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_L2_DCA"))
papi_event_columns.L2_data_cache_miss_rate           <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_L2_DCM"))
papi_event_columns.L2_data_cache_miss_ratio          <-
    append(all_kmeans_columns,c("PAPI_L2_DCA","PAPI_L2_DCM"))
papi_event_columns.L3_total_cache_request_rate       <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_L3_TCA"))
papi_event_columns.L3_total_cache_miss_rate          <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_L3_TCM"))
papi_event_columns.L3_total_cache_miss_ratio         <-
    append(all_kmeans_columns,c("PAPI_L3_TCA","PAPI_L3_TCM"))
papi_event_columns.data_translation_lookaside_buffer_miss_rate <- 
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_TLB_DM"))
papi_event_columns.branch_rate                       <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_BR_INS"))
papi_event_columns.branch_misprediction_rate         <-
    append(all_kmeans_columns,c("PAPI_TOT_INS","PAPI_BR_MSP"))
papi_event_columns.branch_misprediction_ratio       <-
    append(all_kmeans_columns,c("PAPI_BR_INS","PAPI_BR_MSP"))
papi_event_columns.energy_nanojoules                <-
    append(all_kmeans_columns,c("rapl:::PP0_ENERGY:PACKAGE0",
                                "rapl:::DRAM_ENERGY:PACKAGE0"))
#load all datasets
if(LOAD_DATA){
for (performance_measurement in performance_measurements){
    #path <- paste("./hyperthreading_analysis/dense_dataset/3.20GHz/no_hyperthreading_4_threads_core_i7_960/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #path <- paste("./hyperthreading_analysis/dense_dataset/3.20GHz/hyperthreading_4_threads_core_i7_960/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #path <- paste("./hyperthreading_analysis/dense_dataset/4.30GHz/no_hyperthreading_4_threads_core_i7_6700K/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #path <- paste("./hyperthreading_analysis/dense_dataset/4.30GHz/hyperthreading_4_threads_core_i7_6700K/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #path <- paste("./hyperthreading_analysis/dense_dataset/1.60GHz/no_hyperthreading_4_threads_core_i7_960/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #path <- paste("./hyperthreading_analysis/dense_dataset/1.60GHz/hyperthreading_4_threads_core_i7_960/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #path <- paste("./hyperthreading_analysis/dense_dataset/800MHz/no_hyperthreading_4_threads_core_i7_6700K/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #path <- paste("./hyperthreading_analysis/dense_dataset/800MHz/hyperthreading_4_threads_core_i7_6700K/kmeans_default_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    #
    path <- paste("./csets_analysis/results/kmeans_8_cores_",
                  performance_measurement,
                  ".0/",
                  sep="")
    #median kernel execution time: 573 us

    #path <- paste("./csets_analysis/results/kmeans_4_hyperthreaded_cores_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    ##median kernel execution time: 595 us

    #path <- paste("./csets_analysis/results/kmeans_4_no_hyperthreaded_cores_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    ##median kernel execution time: 1003 us

    #path <- paste("./csets_analysis/results/kmeans_4_staggered_no_hyperthreaded_cores_",
    #              performance_measurement,
    #              ".0/",
    #              sep="")
    ##median kernel execution time: 1013 us

    #assign(paste("data.",performance_measurement,sep=""),
    #       ReadAllFilesInDir.List(dir.path=path,
    #                              col=eval(parse(text=paste('papi_event_columns.',performance_measurement,sep='')))))
    assign(paste("data.",performance_measurement,sep=""),
           ReadAllFilesInDir.Aggregate(dir.path=path,
                                       col=eval(parse(text=paste('papi_event_columns.',performance_measurement,sep='')))))
}}

for(n_cluster in seq(1,14)){
#{n_cluster = 14
    for (performance_measurement in performance_measurements){
        path <- paste("./kmeans_scaling_by_increasing_maximum_clusters/coarse_energy_results/kmeans_",
                      n_cluster,
                      "_max_clusters_",
                      performance_measurement,
                      ".0/",
                      sep="") 

        #path <- paste("./kmeans_scaling_by_increasing_maximum_clusters/results/kmeans_",
        #              n_cluster,
        #              "_max_clusters_",
        #              performance_measurement,
        #              ".0/",
        #              sep="")
        assign(paste("data.",performance_measurement,sep=""),
               ReadAllFilesInDir.Aggregate(dir.path=path,
                                           col=eval(parse(text=paste('papi_event_columns.',performance_measurement,sep='')))))
        assign(paste("data.cluster_size_",n_cluster,".",performance_measurement,sep=""),
               ReadAllFilesInDir.Aggregate(dir.path=path,
                                           col=eval(parse(text=paste('papi_event_columns.',performance_measurement,sep='')))))
    }
}

if(PLOT_DENSITY){#density plots
#TODO:
#   - show normality of the kmeans_kernel at each cluster size.
#   - organised the data over an increasing maximum number of clusters.
#   - Since we have an increasing number of iterations till convergence as the maximum clusters parameter increases, sum all kmeans_kernel times and results

for (performance_measurement in performance_measurements){
    #browser()
    #Performance Measurement: time
    if (performance_measurement == 'time'){
        #do the analysis for each region
        data.by_region <- split(data.time,f=data.time$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region_name <- paste(unique(region$region),"_time.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,'time','Time (us)',use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: instructions per cycle
    if (performance_measurement == 'instructions_per_cycle'){
        data.by_region <- split(data.instructions_per_cycle,
                                f=data.instructions_per_cycle$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$ipc <- region$PAPI_TOT_INS/region$PAPI_TOT_CYC
            region_name <- paste(unique(region$region),"_ipc.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,'ipc','Instructions Per Cycle (IPC)',use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L1 Data Cache Request Rate
    if (performance_measurement == 'L1_data_cache_request_rate'){
        data.by_region <- split(data.L1_data_cache_request_rate,
                                f=data.L1_data_cache_request_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L1_data_cache_request_rate <- region$PAPI_L1_DCA/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_L1_data_cache_request_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L1_data_cache_request_rate',
                              'L1 Data Cache Request Rate (req/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L1 Data Cache Miss Rate
    if (performance_measurement == 'L1_data_cache_miss_rate'){
        data.by_region <- split(data.L1_data_cache_miss_rate,
                                f=data.L1_data_cache_miss_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L1_data_cache_miss_rate <-
                region$PAPI_L1_DCM/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_L1_data_cache_miss_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L1_data_cache_miss_rate',
                              'L1 Data Cache Miss Rate (miss/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L1 Data Cache Miss Ratio
    if (performance_measurement == 'L1_data_cache_miss_ratio'){
        data.by_region <- split(data.L1_data_cache_miss_ratio,
                                f=data.L1_data_cache_miss_ratio$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L1_data_cache_miss_ratio <- region$PAPI_L1_DCM/region$PAPI_L1_DCA
            region_name <- paste(unique(region$region),
                                 "_L1_data_cache_miss_ratio.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L1_data_cache_miss_ratio',
                              'L1 Data Cache Miss Ratio (miss/req)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L2 Data Cache Request Rate
    if (performance_measurement == 'L2_data_cache_request_rate'){
        data.by_region <- split(data.L2_data_cache_request_rate,
                                f=data.L2_data_cache_request_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L2_data_cache_request_rate <-
                region$PAPI_L2_DCA/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_L2_data_cache_request_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L2_data_cache_request_rate',
                              'L2 Data Cache Request Rate (req/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L2 Data Cache Miss Rate
    if (performance_measurement == 'L2_data_cache_miss_rate'){
        data.by_region <- split(data.L2_data_cache_miss_rate,
                                f=data.L2_data_cache_miss_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L2_data_cache_miss_rate <-
                region$PAPI_L2_DCM/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_L2_data_cache_miss_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L2_data_cache_miss_rate',
                              'L2 Data Cache Miss Rate (miss/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L2 Data Cache Miss Ratio
    if (performance_measurement == 'L2_data_cache_miss_ratio'){
        data.by_region <- split(data.L2_data_cache_miss_ratio,
                                f=data.L2_data_cache_miss_ratio$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L2_data_cache_miss_ratio <- region$PAPI_L2_DCM/region$PAPI_L2_DCA
            region_name <- paste(unique(region$region),
                                 "_L2_data_cache_miss_ratio.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L2_data_cache_miss_ratio',
                              'L2 Data Cache Miss Ratio (miss/req)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L3 Cache Request Rate
    if (performance_measurement == 'L3_total_cache_request_rate'){
        data.by_region <- split(data.L3_total_cache_request_rate,
                                f=data.L3_total_cache_request_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L3_total_cache_request_rate <- region$PAPI_L3_TCA/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_L3_total_cache_request_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L3_total_cache_request_rate',
                              'L3 Total Cache Request Rate (req/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L3 Total Cache Miss Rate
    if (performance_measurement == 'L3_total_cache_miss_rate'){
        data.by_region <- split(data.L3_total_cache_miss_rate,
                                f=data.L3_total_cache_miss_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L3_total_cache_miss_rate <-
                region$PAPI_L3_TCM/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_L3_total_cache_miss_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L3_total_cache_miss_rate',
                              'L3 Total Cache Miss Rate (miss/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: L3 Total Cache Miss Ratio
    if (performance_measurement == 'L3_total_cache_miss_ratio'){
        data.by_region <- split(data.L3_total_cache_miss_ratio,
                                f=data.L3_total_cache_miss_ratio$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$L3_total_cache_miss_ratio <- region$PAPI_L3_TCM/region$PAPI_L3_TCA
            region_name <- paste(unique(region$region),
                                 "_L3_total_cache_miss_ratio.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'L3_total_cache_miss_ratio',
                              'L3 Total Cache Miss Ratio (miss/req)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: Data TLB Miss Rate
    if (performance_measurement == 'data_translation_lookaside_buffer_miss_rate'){
        data.by_region <- split(data.data_translation_lookaside_buffer_miss_rate,
                                f=data.data_translation_lookaside_buffer_miss_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$data_translation_lookaside_buffer_miss_rate <-
                region$PAPI_TLB_DM/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_data_translation_lookaside_buffer_miss_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'data_translation_lookaside_buffer_miss_rate',
                              'Data TLB Miss Rate (miss/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: Branch Rate
    if (performance_measurement == 'branch_rate'){
        data.by_region <- split(data.branch_rate,
                                f=data.branch_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$branch_rate <- region$PAPI_BR_INS/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_branch_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'branch_rate',
                              'Branch Rate (req/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: Branch Misprediction Rate
    if (performance_measurement == 'branch_misprediction_rate'){
        data.by_region <- split(data.branch_misprediction_rate,
                                f=data.branch_misprediction_rate$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$branch_misprediction_rate <- region$PAPI_BR_MSP/region$PAPI_TOT_INS
            region_name <- paste(unique(region$region),
                                 "_branch_misprediction_rate.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'branch_misprediction_rate',
                              'Branch Misprediction Rate (miss/inst)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: Branch Misprediction Ratio
    if (performance_measurement == 'branch_misprediction_ratio'){
        data.by_region <- split(data.branch_misprediction_ratio,
                                f=data.branch_misprediction_ratio$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region$branch_misprediction_ratio <- region$PAPI_BR_MSP/region$PAPI_BR_INS
            region_name <- paste(unique(region$region),
                                 "_branch_misprediction_ratio.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'branch_misprediction_ratio',
                              'Branch Misprediction Ratio (miss/req)',
                              use_median=TRUE))
            dev.off()
        }
    }
    #Performance Measurement: Branch Misprediction Ratio
    if (performance_measurement == 'energy_nanojoules'){
        data.by_region <- split(data.energy_nanojoules,
                                f=data.energy_nanojoules$region)
        for (i in seq(1,length(data.by_region))){
            region <- data.by_region[[i]]
            region_name <- paste(unique(region$region),"_cpu_energy.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'rapl...PP0_ENERGY.PACKAGE0',
                              'Energy used by all cores (nJ)',
                              use_median=TRUE))
            dev.off()

            region_name <- paste(unique(region$region),"_dram_energy.pdf",sep='')
            printf("Generating Density plot: %s\n",region_name)
            pdf(region_name)
            print(lsb_density(region,
                              'rapl...DRAM_ENERGY.PACKAGE0',
                              'Energy used by DRAM (nJ)',
                              use_median=TRUE))
            dev.off()
        }
    }
}}

if(PLOT_ENERGY_SCALING){ #Scaling 
data.energy_nanojoules <- data.frame()
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_1.energy_nanojoules,'cluster_size' = 1))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_2.energy_nanojoules,'cluster_size' = 2))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_3.energy_nanojoules,'cluster_size' = 3))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_4.energy_nanojoules,'cluster_size' = 4))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_5.energy_nanojoules,'cluster_size' = 5))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_6.energy_nanojoules,'cluster_size' = 6))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_7.energy_nanojoules,'cluster_size' = 7))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_8.energy_nanojoules,'cluster_size' = 8))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_9.energy_nanojoules,'cluster_size' = 9))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_10.energy_nanojoules,'cluster_size' = 10))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_10.energy_nanojoules,'cluster_size' = 11))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_10.energy_nanojoules,'cluster_size' = 12))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_10.energy_nanojoules,'cluster_size' = 13))
data.energy_nanojoules <- rbind(data.energy_nanojoules, cbind(data.cluster_size_10.energy_nanojoules,'cluster_size' = 14))

data.energy_joules <- data.energy_nanojoules
data.energy_joules$rapl...PP0_ENERGY.PACKAGE0 <- data.energy_joules$rapl...PP0_ENERGY.PACKAGE0*10^-9
data.energy_joules$rapl...DRAM_ENERGY.PACKAGE0 <- data.energy_joules$rapl...DRAM_ENERGY.PACKAGE0*10^-9

kernel <- data.energy_joules[which(data.energy_joules$region == 'kmeansCuda'),]

#ggplot(kernel, aes(x=factor(cluster_size), y=time)) + stat_summary(fun.y="median", geom="line")
#ggplot(kernel, aes(x=factor(cluster_size), y=time)) + stat_summary(fun.y="median", geom="line",aes(group = 1))
pdf('energy_vs_cluster_count.pdf')
p <- ggplot(kernel, aes(x=factor(cluster_size), y=rapl...PP0_ENERGY.PACKAGE0)) +
    stat_summary(fun.y="median", geom="line",aes(group = 1)) +
    ylab('Energy (J)') + xlab('Maximum Number of Clusters')
print(p)
dev.off()
pdf('time_vs_cluster_count.pdf')
p <- ggplot(kernel, aes(x=factor(cluster_size), y=time)) +
    stat_summary(fun.y="median", geom="line",aes(group = 1)) +
    ylab('Time (us)') + xlab('Maximum Number of Clusters')
print(p)
dev.off()

}

if(PLOT_L1_SCALING){ #Scaling 
    miss_rate <- load_directories("./fitting_problem_for_L1_cache_powersave/results/kmeans_##_sized_matrix_L1_data_cache_miss_rate.0/",
                                  seq(230,250),
                                  papi_event_columns.L1_data_cache_miss_rate)

    #just the compute region
    miss_rate <- subset(miss_rate,region=='kmeans_kernel')

    miss_rate$L1_data_cache_miss_rate <-
        miss_rate$PAPI_L1_DCM/miss_rate$PAPI_TOT_INS

    #plot densities (for each problem size)
    for (i in seq(230,250)){
        region <- subset(miss_rate,size==i)
        pdf(paste("L1_time_density_at_",i,"_objects.pdf",sep=""))
        print(lsb_density(region,
                          'time',
                          'Time (us)',
                          use_median=TRUE))
        dev.off()
        pdf(paste("L1_miss_rate_density_at_",i,"_objects.pdf",sep=""))
        print(lsb_density(region,
                          'L1_data_cache_miss_rate',
                          'L1 Data Cache Miss Rate (miss/inst)',
                          use_median=TRUE))
        dev.off()
    }

    pdf('L1_scaling_time.pdf')
    p <- ggplot(miss_rate, aes(x=factor(size), y=time)) +
        stat_summary(fun.y="median", geom="line",aes(group = 1)) +
        ylab('Time (us)') + xlab('Number of Objects')
    print(p)
    dev.off()
    pdf('L1_miss_rate_scaling.pdf')
    p <- ggplot(miss_rate, aes(x=factor(size), y=L1_data_cache_miss_rate)) +
        stat_summary(fun.y="median", geom="line",aes(group = 1)) +
        ylab('Cache Miss Rate % (miss/inst)') + xlab('Number of Objects')
    print(p)
    dev.off()
}

if(PLOT_L2_SCALING){ #Scaling 
    miss_rate <- load_directories("./fitting_problem_for_L2_cache/results/kmeans_##_sized_matrix_L2_data_cache_miss_rate.0/",
                                  seq(460,480),
                                  papi_event_columns.L2_data_cache_miss_rate)

    #just the compute region
    miss_rate <- subset(miss_rate,region=='kmeans_kernel')

    miss_rate$L2_data_cache_miss_rate <-
        miss_rate$PAPI_L2_DCM/miss_rate$PAPI_TOT_INS

    #plot densities (for each problem size)
    for (i in seq(460,480)){
        region <- subset(miss_rate,size==i)
        pdf(paste("L2_time_density_at_",i,"_objects.pdf",sep=""))
        print(lsb_density(region,
                          'time',
                          'Time (us)',
                          use_median=TRUE))
        dev.off()
        pdf(paste("L2_miss_rate_density_at_",i,"_objects.pdf",sep=""))
        print(lsb_density(region,
                          'L2_data_cache_miss_rate',
                          'L2 Data Cache Miss Rate (miss/inst)',
                          use_median=TRUE))
        dev.off()
        
    }

    pdf('L2_scaling_time.pdf')
    p <- ggplot(miss_rate, aes(x=factor(size), y=time)) +
        stat_summary(fun.y="median", geom="line",aes(group = 1)) +
        ylab('Time (us)') + xlab('Number of Objects')
    print(p)
    dev.off()
    pdf('L2_miss_rate_scaling.pdf')
    p <- ggplot(miss_rate, aes(x=factor(size), y=L2_data_cache_miss_rate)) +
        stat_summary(fun.y="median", geom="line",aes(group = 1)) +
        ylab('Cache Miss Rate % (miss/inst)') + xlab('Number of Objects')
    print(p)
    dev.off()
}

if(PLOT_L3_SCALING){ #Scaling 
    miss_rate <- load_directories("./fitting_problem_for_L3_cache/results/kmeans_##_sized_matrix_L3_total_cache_miss_rate.0/",
                                  seq(3980,4019),
                                  papi_event_columns.L3_total_cache_miss_rate)

    #just the compute region
    miss_rate <- subset(miss_rate,region=='kmeans_kernel')
    miss_rate$L3_total_cache_miss_rate <-
        miss_rate$PAPI_L3_TCM/miss_rate$PAPI_TOT_INS

    #plot densities (for each problem size)
    for (i in seq(3980,4019)){
        region <- subset(miss_rate,size==i)
        pdf(paste("L3_time_density_at_",i,"_objects.pdf",sep=""))
        print(lsb_density(region,
                          'time',
                          'Time (us)',
                          use_median=TRUE))
        dev.off()
        pdf(paste("L3_miss_rate_density_at_",i,"_objects.pdf",sep=""))
        print(lsb_density(region,
                          'L3_total_cache_miss_rate',
                          'L3 Total Cache Miss Rate (miss/inst)',
                          use_median=TRUE))
        dev.off()
    }

    pdf('L3_scaling_time.pdf')
    p <- ggplot(miss_rate, aes(x=factor(size), y=time)) +
        stat_summary(fun.y="median", geom="line",aes(group = 1)) +
        ylab('Time (us)') + xlab('Number of Objects')
    print(p)
    dev.off()
    pdf('L3_miss_rate_scaling.pdf')
    p <- ggplot(miss_rate, aes(x=factor(size), y=L3_total_cache_miss_rate)) +
        stat_summary(fun.y="median", geom="line",aes(group = 1)) +
        ylab('Cache Miss Rate % (miss/inst)') + xlab('Number of Objects')
    print(p)
    dev.off()
}
