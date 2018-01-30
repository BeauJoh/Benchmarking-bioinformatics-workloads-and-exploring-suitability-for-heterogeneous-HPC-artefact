
source("utils.R")
source("stats.R")
source("aes.R")
source("functions.R")

devices <- c('xeon_es-2697v2','i7-6700k','titanx','gtx1080','gtx1080ti','k20c','k40c','knl')#,'firepro_s9150')
sizes <- c('tiny','small','medium','large')
#load data if it doesn't exist in this environment
#to force a reload:
#remove(data.kmeans)

SumPerRunReduction <- function(x){
    z <- data.frame()
    for (y in unique(x$run)){
        z <- rbind(z,data.frame('time'=sum(x[x$run == y,]$time),'run'=y))
    }
    return(z)
}

if (!exists("data.kmeans")){
    data.kmeans <- data.frame()
    columns <- c('region','number_of_objects','number_of_features','iteration_number_hint_until_convergence','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_kmeans_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.kmeans <- rbind(data.kmeans, x)
        }
    }
}

if(!exists("data.lud")){
    data.lud <- data.frame(data.frame())
    columns <- c('region','matrix_dimension','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_lud_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.lud <- rbind(data.lud, x)
        }
    }
}

if(!exists("data.csr")){
    data.csr <- data.frame()
    columns <- c('region','number_of_matrices','workgroup_size','execution_number','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_csr_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            SeparateAllNAsInFilesInDir(dir.path=path) 
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.csr <- rbind(data.csr, x)
        }
    }
}

if(!exists("data.fft")){
    data.fft <- data.frame()
    columns <- c('signal_length','region','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_openclfft_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.fft <- rbind(data.fft, x)
        }
    }
}

if(!exists("data.dwt")){
    data.dwt <- data.frame()
    columns <- c('region','dwt_level','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_dwt2d_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.dwt <- rbind(data.dwt, x)
        }
    }
}

if(!exists("data.gem")){
    data.gem <- data.frame()
    columns <- c('number_of_residues','number_of_vertices','region','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_gem_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.gem <- rbind(data.gem, x)
        }
    }
}

if(!exists("data.srad")){
    data.srad <- data.frame()
    columns <- c('region','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_srad_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.srad <- rbind(data.srad, x)
        }
    }
}

if(!exists("data.crc")){
    data.crc <- data.frame()
    columns <- c('number_of_pages','page_size','region','id','time','overhead')
    for(device in devices){
        for(size in sizes){
            path = paste("../data/time_data/",device,"_crc_",size,"_time.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x$device <- device
            x$size <- size
            data.crc <- rbind(data.crc, x)
        }
    }
}

if (!exists("data.all")){
    data.all <- data.frame()
    print("munging data...")
    ##parse kmeans
    for(device in devices){
        for(size in sizes){
            x <- data.kmeans[data.kmeans$region=="kmeans_kernel" & data.kmeans$device == device & data.kmeans$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='kmeans',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
    #munge lud
    for(device in devices){
        for(size in sizes){
            x <- data.lud[(data.lud$region=="diagonal_kernel"|data.lud$region=="perimeter_kernel"|data.lud$region=="internal_kernel") & data.lud$device == device & data.lud$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='lud',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
    #munge csr
    for(device in devices){
        for(size in sizes){
            x <- data.csr[data.csr$region=="csr_kernel" & data.csr$device == device & data.csr$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='csr',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
    #munge fft
    for(device in devices){
        for(size in sizes){
            x <- data.fft[data.fft$region=="fft_kernel" & data.fft$device == device & data.fft$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='fft',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
    #munge dwt
    for(device in devices){
        for(size in sizes){
            x <- data.dwt[data.dwt$region=="kl_fdwt53Kernel_kernel" & data.dwt$device == device & data.dwt$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='dwt',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
    #munge gem
    for(device in devices){
        for(size in sizes){
            x <- data.gem[data.gem$region=="gem_kernel" & data.gem$device == device & data.gem$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='gem',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
    #munge srad
    for(device in devices){
        for(size in sizes){
            x <- data.srad[(data.srad$region=="srad1_kernel" | data.srad$region=="srad2_kernel") & data.srad$device == device & data.srad$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='srad',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
    #munge crc
    for(device in devices){
        for(size in sizes){
            x <- data.crc[data.crc$region=="kernel_compute_kernel"  & data.crc$device == device & data.crc$size == size,]
            x <- SumPerRunReduction(x)
            data.all <- rbind(data.all,data.frame('application'='crc',
                                                  'device'=device,
                                                  'size'=size,
                                                  'time'=x$time,
                                                  'run'=x$run))
        }
    }
}

if (!exists("data.energy")){
    SumEnergyPerRunReduction <- function(x){
        z <- data.frame()
        for (y in unique(x$run)){
            z <- rbind(z,data.frame('energy'=sum(x[x$run == y,]$energy),'run'=y))
        }
        return(z)
    }

    AppendColumnsPerDevice <- function(columns,device){
        if (device == 'i7-6700k'){
            columns <- c(columns,'rapl:::PP0_ENERGY:PACKAGE0','rapl:::DRAM_ENERGY:PACKAGE0')
        }
        else{
            columns <- c(columns,'nvml:::GeForce_GTX_1080:power','nvml:::GeForce_GTX_1080:temperature')
        }
        return(columns)
    }
    
    GetExtension <- function(device){
        if (device == 'i7-6700k'){
            return('_cpu_energy_nanojoules')
        }
        else{
            return('_gpu_energy_milliwatts')
        }
    }

    ConvertToJoules <- function(data,device){
        if(device == 'i7-6700k'){
            data$energy <- data$rapl...PP0_ENERGY.PACKAGE0*10**-9
        }
        else{
            data$energy <- ((data$nvml...GeForce_GTX_1080.power*10**-3) * (data$time*10**-6))
        }
        return(data)
    }

    data.energy <- data.frame()
    energy_devices <- c('i7-6700k','gtx1080')
    energy_sizes <- c('large')

    for(device in energy_devices){
        for(size in energy_sizes){
            #kmeans
            columns <- c('region','number_of_objects','number_of_features','iteration_number_hint_until_convergence','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            extension<-GetExtension(device)
            path = paste("../data/energy_data/",device,"_kmeans_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[x$region=="kmeans_kernel",]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='kmeans',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))
            #lud
            columns <- c('region','matrix_dimension','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            path = paste("../data/energy_data/",device,"_lud_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[(x$region=="diagonal_kernel"|x$region=="perimeter_kernel"|x$region=="internal_kernel"),]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='lud',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))
            #csr
            columns <- c('region','number_of_matrices','workgroup_size','execution_number','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            path = paste("../data/energy_data/",device,"_csr_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            SeparateAllNAsInFilesInDir(dir.path=path) 
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[(x$region=="csr_kernel"),]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='csr',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))
            #fft
            columns <- c('signal_length','region','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            path = paste("../data/energy_data/",device,"_openclfft_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[(x$region=="fft_kernel"),]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='fft',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))
            #dwt
            columns <- c('region','dwt_level','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            path = paste("../data/energy_data/",device,"_dwt2d_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[(x$region=="kl_fdwt53Kernel_kernel"),]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='dwt',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))
            #gem
            columns <- c('number_of_residues','number_of_vertices','region','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            path = paste("../data/energy_data/",device,"_gem_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[(x$region=="gem_kernel"),]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='gem',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))
            #srad
            columns <- c('region','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            path = paste("../data/energy_data/",device,"_srad_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[(x$region=="srad1_kernel"|x$region=="srad2_kernel"),]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='srad',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))
            #crc
            columns <- c('number_of_pages','page_size','region','id','time','overhead')
            columns<-AppendColumnsPerDevice(columns,device)
            path = paste("../data/energy_data/",device,"_crc_",size,extension,".0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=columns)
            x <- x[(x$region=="kernel_compute_kernel"),]
            x <- ConvertToJoules(x,device)
            x <- SumEnergyPerRunReduction(x)
            data.energy <- rbind(data.energy,data.frame('application'='crc',
                                                        'device'=device,
                                                        'size'=size,
                                                        'energy'=x$energy,
                                                        'run'=x$run))        
        }
    }
}

if (!exists("data.cache")){
    SumMissRatePerRunReduction <- function(x,feature){
    z <- data.frame()
    for (y in unique(x$run)){
        z <- rbind(z,data.frame('count'=eval(parse(text=paste("sum(x[x$run == y,]$",feature,')',sep=''))),'run'=y))
    }
    return(z)
}
    data.cache <- data.frame()
    device <- c('i7-6700k')
    sizes <- c('tiny','small','medium','large')
    for(size in sizes){
            #kmeans
            columns <- c('region','number_of_objects','number_of_features','iteration_number_hint_until_convergence','id','time','overhead')
            path = paste("../data/cache_data/",device,"_kmeans_",size,"_L1_data_cache_miss_rate.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=c(columns,'PAPI_TOT_INS','PAPI_L1_DCM'))
            x <- x[x$region=="kmeans_kernel",]
            l1misses <- SumMissRatePerRunReduction(x,'PAPI_L1_DCM')
            l1ins <- SumMissRatePerRunReduction(x,'PAPI_TOT_INS')
            data.cache <- rbind(data.cache,data.frame('application'='kmeans',
                                                      'device'=device,
                                                      'size'=size,
                                                      'cache_level'='L1',
                                                      'misses'=l1misses$count/l1accesses$count,
                                                      'total_instructions'=l1ins$count,
                                                      'run'=l1misses$run))

            path = paste("../data/cache_data/",device,"_kmeans_",size,"_L2_data_cache_miss_rate.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=c(columns,'PAPI_TOT_INS','PAPI_L2_DCM'))
            x <- x[x$region=="kmeans_kernel",]
            l2misses <- SumMissRatePerRunReduction(x,'PAPI_L2_DCM')
            l2ins <- SumMissRatePerRunReduction(x,'PAPI_TOT_INS')
            data.cache <- rbind(data.cache,data.frame('application'='kmeans',
                                                      'device'=device,
                                                      'size'=size,
                                                      'cache_level'='L2',
                                                      'misses'=l2misses$count/l2accesses$count,
                                                      'total_instructions'=l2ins$count,
                                                      'run'=l2misses$run))

            path = paste("../data/cache_data/",device,"_kmeans_",size,"_L3_total_cache_miss_rate.0/",sep='')
            print(paste("loading:",path))
            x <- ReadAllFilesInDir.AggregateWithRunIndex(dir.path=path,col=c(columns,'PAPI_TOT_INS','PAPI_L3_TCM'))
            x <- x[x$region=="kmeans_kernel",]
            l3misses <- SumMissRatePerRunReduction(x,'PAPI_L3_TCM')
            l3ins <- SumMissRatePerRunReduction(x,'PAPI_TOT_INS')
            data.cache <- rbind(data.cache,data.frame('application'='kmeans',
                                                      'device'=device,
                                                      'size'=size,
                                                      'cache_level'='L3',
                                                      'misses'=l3misses$count/l3accesses$count,
                                                      'total_instructions'=l3ins$count,
                                                      'run'=l3misses$run))


    }
}

