# Contour extractor funktion
contour_extractor <- function(analysis, max = length(xl[[analysis]])) {
  output = list(segments = data.frame(), cont = data.frame(), stat_cont = data.frame(), pbs = data.frame())
  starttime = Sys.time()
  fjern_stentvars_fra_edges <- c("de.mean_s_a","de.min_s_a","de.min_s_a_frame","de.mean_avg_s_d","de.min_s_d","de.max_s_d",
                                 "pe.mean_s_a","pe.min_s_a","pe.min_s_a_frame","pe.mean_avg_s_d","pe.min_s_d","pe.max_s_d")
  
  pb <- txtProgressBar(min = 1, max = length(xl[[analysis]]), style = 3, width = 100)
  print(paste0("Extracting: ",analysis,"...")); cat("\n")
  
  for (i in 1:min(length(xl[[analysis]]),max)){
    setTxtProgressBar(pb,i)
    id <- str_split(basename(xl[[analysis]][i]),".x")[[1]][1]                            # Beregner id fx xxx
    #print(paste0(id," (",i,"/", length(xl[[analysis]]),")"))
    raw <- read_excel(path = paste0(path,xl[[analysis]][i]),                             # path til excel ark
                      sheet = "OrgSheet", range = cell_limits(c(46,1),c(NA,13)),         # Extract række 46 kolonne 1 (svt. segments) til kolonne 13.
                      col_names = F, .name_repair = "unique_quiet")                      # Printer ikke besked om at der mangler kolonnenavne.
    
    # Pullback speed (til calc length/NIA volume calculation)
    pbs = data.frame(pbs_val = as.numeric(raw[1,3]), slice_thickness = as.numeric(raw[3,3]), fps = as.numeric(raw[2,3]),
                     id = id)
    
    output$pbs <- bind_rows(output$pbs,pbs)
    
    # CONTOURS
    cont <- extract_raw_contours(raw,id)
    output$cont <- bind_rows(output$cont,cont)

    # SEGMENTS
    segments <- extract_raw_segments(raw,id)
    output$segments <- bind_rows(output$segments,segments)                               # Binder segmenterns sammen på tværs af patienter. # Obs xxx har PE længde > 5 mm gr aneurisme (OK).
    
    # Beregniner statistikker for hvert segment.
    stat_cont <- data.frame(
      id = id,
      de = calc_segment(cont,as.numeric(segments$start_de),as.numeric(segments$end_de),analysis),
      t =  calc_segment(cont,as.numeric(segments$start_t), as.numeric(segments$end_t),analysis),
      pe = calc_segment(cont,as.numeric(segments$start_pe),as.numeric(segments$end_pe),analysis)) 
    
    output$stat_cont <- bind_rows(output$stat_cont,stat_cont)
  }

    output$segments <- output$segments %>%
    select(id,start_de,end_de,length_mm_de,start_t,end_t,length_mm_t,start_pe,end_pe,length_mm_pe) %>%
    mutate(across(2:10, as.numeric))

  # Tilføjer radiant analyse (xxx final+pre)
  source("Scripts/qcu extractor scripts/Extract radiant.R")
  if (analysis == "final") {
    final_radiant_xxx_full <- final_radiant_xxx_full()
    output$segments <- bind_rows(output$segments,final_radiant_xxx_full$segments)
    output$cont <- bind_rows(output$cont,final_radiant_xxx_full$cont)
    output$stat_cont <- bind_rows(output$stat_cont,final_radiant_xxx_full$stat_cont)
  } else if (analysis == "pre") {
    pre_radiant_xxx_full <- pre_radiant_xxx_full()
    output$segments <- bind_rows(output$segments,pre_radiant_xxx_full$segments)
    output$cont <- bind_rows(output$cont,pre_radiant_xxx_full$cont)
    output$stat_cont <- bind_rows(output$stat_cont,pre_radiant_xxx_full$stat_cont)
  }
  
  # Tilføjer splittede excels
  source("Scripts/qcu extractor scripts/Extract split excel.R")
  if (analysis == "final") {
    combined_excels  <- split_contour_extractor("final")
    output$segments  <- bind_rows(output$segments,combined_excels$segments)
    output$cont      <- bind_rows(output$cont,combined_excels$cont)
    output$stat_cont <- bind_rows(output$stat_cont,combined_excels$stat_cont)
  } else if (analysis == "pre") {
    combined_excels  <- split_contour_extractor("pre")
    output$segments  <- bind_rows(output$segments,combined_excels$segments)
    output$cont      <- bind_rows(output$cont,combined_excels$cont)
    output$stat_cont <- bind_rows(output$stat_cont,combined_excels$stat_cont)
  }
    
  # Tilføjer specielle pre-excles til pbs (split excels + radiant)
  if (analysis == "pre"){
    
    output$pbs <- output$pbs %>%
      add_row(pbs_val = 18, slice_thickness = 0.1, fps = 180, id = "xxx") %>% # xxx (radiant)
      add_row(pbs_val = 18, slice_thickness = 0.1, fps = 180, id = "xxx") # Den længste deposit er på prox så tager dens pbs
  }

  #Fixer dataframes for readability
  output$stat_cont <- output$stat_cont %>%
    select(-any_of(fjern_stentvars_fra_edges))

  # Konklusion
  print(paste0("Processing time: ",as.numeric(round(difftime(Sys.time(),starttime, units = "secs"),1)), " secs"))
  
  return(output)
}

extract_raw_segments <- function(data,id){
  segments <- data[1:4,7:8][-2,] %>%                                                    # Fjerner række 2 fordi den er altid tom.
    rename(range = "...7",length_mm = "...8") %>% 
    separate(range, into = c("start","end"), sep = " - ", convert = T) %>% 
    mutate(segment = c("t","de","pe"), id = id) %>% 
    select(id,segment,start,end,length_mm) %>% 
    pivot_wider(names_from = segment, values_from = c(3:5))    
  
  return(segments)
}

extract_raw_contours <- function(data, id) {
  cont <- data[16:nrow(data),] %>%                                                     # Fra start af konturer til sidste konturrække
    select(-c(2:5)) %>%                                                                # Disse er altid NA
    setNames(c("frame","l_a","l_avg_d","l_mi_d","l_ma_d",
               "s_a","s_avg_d","s_mi_d","s_ma_d")) %>%
    filter(!is.na(frame)) %>%                                                          # Fjerner frames uden målinger i
    mutate_if(is.character,as.numeric) %>%
    mutate(id = id) %>% 
    select(id,names(.))

  return(cont)
}

# Calculate statistic in segment
calc_segment <- function(data, start_fr, end_fr, analysis) {
  d_sub <- data %>% 
    filter(frame >= start_fr, frame <= end_fr)
  
  # Hvis det er pre analyse, så beregnes kun på lumen mål.
  result <- list(
    mean_l_a      = calc_stat(d_sub$l_a,mean),                  # Average lumen area
    min_l_a       = calc_stat(d_sub$l_a,min),                   # Minimum lumen area (MLA)
    min_l_a_frame = calc_stat(d_sub$l_a,which.min,d_sub$frame), # Frame for MLA
    mean_avg_l_d  = calc_stat(d_sub$l_avg_d,mean))              # Gennemsnitlige average lumen diameter    
  
  # Hvis det er final eller fu, så inkluderes stent mål.  
  if (analysis %in% c("final","fu")) {
    result <- c(result,list(
      mean_s_a      = calc_stat(d_sub$s_a,mean),                  # Average stent area
      min_s_a       = calc_stat(d_sub$s_a,min),                   # Minimum stent area (MSA)
      min_s_a_frame = calc_stat(d_sub$s_a,which.min,d_sub$frame), # Frame for MSA
      mean_avg_s_d  = calc_stat(d_sub$s_avg_d,mean),              # Gennemsnitlige average stent diameter
      min_s_d       = calc_stat(d_sub$s_mi_d,min),                # mindste stent diameter (MSD)
      max_s_d       = calc_stat(d_sub$s_ma_d,max)))               # Største stent diameter
  }
  return(result)
}

# Hjælper variabel til at beregne statistik
## var =  variabel som beregningen skal udføres på (l_a, s_a, etc), 
# stat_func = statistisk funktion (mean, min, etc)
# framevar = frame variablen (til at finde frame for MLA/MSA)
calc_stat <- function(var, stat_func,framevar) {
  tryCatch({
    if (all(is.na(var))) {                     # Hvis der ingen værdier er i segmentet, så retuner NA (ellers giver min() warnings)
      NA
    } else {
      if (!(identical(stat_func,which.min))) { # Hvis stat_func er noget andet end which.min
        stat_func(var, na.rm = T)
      } else {                                 # Hvis stat_func == which.min, så returner frame for MLA
        return(framevar[which.min(var)])
      }
    }
  })
}
