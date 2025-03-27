root_path <- "..."

plaque_extractor <- function(max = NA) {
  output <- list(plaque_df = data.frame(), calc_thick_df = data.frame()) 
  starttime = Sys.time()
  counter = 0
  pb <- txtProgressBar(min = 1, max = length(xl$pre), style = 3, width = 100)
  print(paste0("Extracting: plaques")); cat("\n")

  for (i in xl$pre){
    #print(i)
    if (!is.na(max) & counter == max) # Max angiver antallet af iterationer hvis angivet.
      break
    
    counter = counter + 1
    setTxtProgressBar(pb,counter)
    id <- str_extract(i, pattern = "([0-9]+-[0-9]+_(final|fu|pre))")
    
    #print(paste0(id," (",counter,"/", length(xl$pre),")"))
    d_raw <- read_excel(paste0(root_path,i), sheet = "OCTresults", col_names = c("desc","frame_col","value","var","dummy"))

    d <- d_raw %>% 
      select(-dummy) %>% 
      slice(-c(1:9)) %>%                                                                   # Fjerner de første 9 rækker
      filter_all(any_vars(!is.na(.))) %>%                                                  # Fjerner rækker hvor alle variabler er NA.
      filter(is.na(desc) | desc != "[IMAGENR]") %>%                                        # Fjerner rækker med [IMAGENR] - nødvenidgt med is.na(desc) ellers fjernes de også ved desc != [IMAGENR] %>% 
      mutate(row_raw = row_number()) %>% 
      slice(-c(which(desc == "[OCT_SETTINGS]"):nrow(.)))                                   # Fjerner fra rækken med "OCT_SETTINGS" til og med slutningen på dataframe).
  
    ImageNr.rows <- which(d$desc == "ImageNr")                                             # Finder de rækker hvor ImageNr er angivet

    # Datasæt for rækkerintervaller for hvert frame  
    frame_intervaller <- data.frame(                                                       
      start = ImageNr.rows,                                                                # Data for et frame startes her 
      end = c(ImageNr.rows[-1] -1,nrow(d))) %>%                                            # Fjerner 1. værdi (start-værdi) og trækker en fra svt. række for slut på framet.
      mutate(interval_nummer = row_number())
  
    for (f in frame_intervaller$interval_nummer){
      # Subsetter data for hvert frame interval
      frame_data <- d[c(frame_intervaller$start[f]:frame_intervaller$end[f]),] # Data for hvert frame (defineret ud fra rækkeinterval)
      frame <- frame_data$frame_col[1]
      
      # EXTRACTER PLAQUE VINKLER FOR HVERT FRAME
      if ("Angle" %in% frame_data$value) { 
        
        # Finder start og slut række (row_raw) for plaquevinklerne
        start_row_raw <- as.numeric(frame_data %>% filter(value == "Angle") %>% pull(row_raw) + 1)  # row_raw for rækken efter "Angle"
        end_row_raw   <- as.numeric(max(frame_data$row_raw))                                        # row_raw for rækken sidst i datasættet (vinkler slutter altid til sidst i datasættet)
        
        # Midlertidigt datasæt for plaquevinkler.
        temp_data <- frame_data %>%
          filter(row_raw %in% start_row_raw:end_row_raw) %>% 
          mutate(frame = frame, id = id)

        output$plaque_df <- bind_rows(output$plaque_df,temp_data)
      }

      # EXTRACTER KALKTYKKELSER
      if ("Distance" %in% frame_data$value) {
        start_row <- frame_data %>% filter(value == "Distance") %>% pull(row_raw) + 1 # Værdien ligger i row_raw 1 efter "Distance" rækken. Satser på at der max er 1 distance for hvert frame
 
        # Sidste row for distance afhænger af om der er vinkler eller ej
        end_row <- if ("Angle" %in% frame_data$value) {
          frame_data %>%
            filter(row_raw >= start_row, is.na(value)) %>% #(hvis vinkel da slutter distancer 1 før første NA,
            slice(1) %>% pull(row_raw) - 1
        } else {
          max(frame_data$row_raw)                          # Hvis ingen vinkel da tag sidste række.
        }
        # Midlertidigt datasæt for kalktykkelserne. Variablerne skal have navnene value, var og frame.
        temp_data <- frame_data %>%
          filter(row_raw %in% start_row:end_row) %>%
          mutate(var = "calc_thickness",
                 frame = frame,
                 id = id)
        
        output$calc_thick_df <- bind_rows(output$calc_thick_df,temp_data)
      }
  }
  }
  # Fjerner mediamedia målinger, samler calc_thick_df og plaque_df i én df.
  output2 <- remove_mediamedia_dist(output) # id, value, var, frame.
  # 
  # Tilføjers splittede excels (kun xxx_pre)
  source("Scripts/qcu extractor scripts/Extract split excel.R")
  combined_excels  <- plaque_split_extractor()
  output2  <- bind_rows(output2,combined_excels)
   
  # Tilføjer radiant pre (kun xxx_pre)
  source("Scripts/qcu extractor scripts/Extract radiant.R")
  radiant_plaque <- plaque_radiant_xxx()
  output2 <- bind_rows(output2,radiant_plaque)

  # Konklusion
  cat("\n")
  print(paste0("Processing time: ",as.numeric(round(difftime(Sys.time(),starttime, units = "secs"),1)), " secs"))
  return(output2)
}

remove_mediamedia_dist <- function(data){
  comb <- bind_rows(data$plaque_df,data$calc_thick_df)
  
  # Fjerner rækker hvor målinger er lavet i edges (må være en fejl eller gammeL MM måling)
  segs_plaque <- merge(comb,pre$segments, by = "id") %>% 
    select(-c(2,3,row_raw)) %>%
    mutate(value = as.numeric(value), 
           frame = as.numeric(frame),
           var = as.factor(var),
           val_id = row_number()) # Unique row identifier som jge bruger til at fjerne de forkerte målinger med.
  
  # Identificerer målinger som er lavet i edges = 75 mål.
  measures_in_edges_for_removal <- segs_plaque %>%
    filter(frame <= end_de | frame >= start_pe) # Obs alle er kalktykkelser og >2.7mm (dette må nødvendigvis være MM mål som skal fjernes.)
  
  segs_plaque <- segs_plaque %>% 
    filter(!val_id %in% measures_in_edges_for_removal$val_id) %>% 
    select(id, value, var, frame)

  return(segs_plaque)
}

# valid_plaques <- c("calc_thickness","Dissection",
#                    "Emb_cal_nocrack","Emb_cal_crack",
#                    "Pro_cal_nocrack","Pro_cal_crack")
