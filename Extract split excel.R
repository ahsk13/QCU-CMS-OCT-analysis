# Extracter excel fra splitted-excel (dvs hvor QCU analysen er delt i prox og dist, eller 3 dele)


# Overblik over pt med multiple excels per undersøgelse
# d %>%
#   filter(qcu_prs_split_excels == 1 | qcu_pos_split_excels == 1 | qcu_fu_split_excels == 1) %>%
#   select(id,qcu_prs_split_excels,qcu_pos_split_excels,qcu_fu_split_excels)

# xl$split_excel_final
# xl$split_excel_pre

# Preparation
# Dist og mid frames skal offsettes svt. at de distale pullbacks ligger før det mest proksimale (1 frame fra).
frame_offset <- data.frame(id_split2 = as.character(), offset = as.numeric()) %>%  # Skal være id_split2, for ikke at modarbejde id_split i extract funktionen.
  add_row(id_split2 = "xxx_final_dist", offset = 160) %>% 
  add_row(id_split2 = "xxx_final_dist", offset = 226-24) %>%                    # prox target starter i fr 25 (merger segmenterne på 1 frame før). 
  add_row(id_split2 = "xxx_final_dist", offset = -(306-59)) %>% 
  add_row(id_split2 = "xxx_final_mid", offset = -(312-213)) %>%                 # OBS REVERSE
  add_row(id_split2 = "xxx_final_dist", offset = -(446-122)) %>%                # OBS REVERSE
  add_row(id_split2 = "xxx_pre_dist", offset = 230-95)

# Angiver manuelt segmenter som sørger for at de splittede excels kommer tilat lægge lige efter hinanden.
segments_split <- data.frame(
  id = as.character(), 
  start_de = as.numeric(), end_de = as.numeric(), length_mm_de = as.numeric(),
  start_t  = as.numeric(), end_t =  as.numeric(), length_mm_t  = as.numeric(),
  start_pe = as.numeric(), end_pe = as.numeric(), length_mm_pe = as.numeric()) %>% 
  add_row(id = "xxx_final",
          start_de = 19-160, end_de = 43-160, length_mm_de = 5, 
          start_t = 44-160,end_t = 387, length_mm_t = 23.2+38.8,
          start_pe = NA, end_pe = NA, length_mm_pe = NA) %>% 
  add_row(id = "xxx_final",
          start_de = 0-202, end_de = 11-202, length_mm_de = 2.4, 
          start_t = 12-202,end_t = 218, length_mm_t = 43+19.4,
          start_pe = NA, end_pe = NA, length_mm_pe = NA) %>% 
  add_row(id = "xxx_final",
          start_de = NA, end_de = NA, length_mm_de = NA, 
          start_t = 135,end_t = 550, length_mm_t = 49+34.2,# Skiftet start_t og end_t (pga. reverse) ellers regner calc_segment forkert.
          start_pe = 114, end_pe = 134, length_mm_pe = 4.2) %>% 
  add_row(id = "xxx_final",
          start_de = NA, end_de = NA, length_mm_de = NA, 
          start_t = 180,end_t = 698, length_mm_t = 26.4+26.8+50.6, # Skiftet start_t og end_t (pga. reverse) ellers regner calc_segment forkert.
          start_pe = 192, end_pe = 192, length_mm_pe = 0) %>% 
  add_row(id = "xxx_pre",
          start_de = NA, end_de = NA, length_mm_de = NA, 
          start_t = -6,end_t = 296, length_mm_t = 20.4+20.1,
          start_pe = NA, end_pe = NA, length_mm_pe = NA)

# EXTRACTION
# #analysis = "final"; cont = output$cont %>% filter(id == "xxx_final",frame >= -141,frame <= -117); id = "xxx_final"
# df <- split_contour_extractor("final")
# cont <- df$cont %>% filter(id=="xxx_final")
# split_segments_extractor("final",cont,id) #%>% dim()

split_segments_extractor <- function(analysis,cont,id) {
  output_s_s_c <- list()
  segments <- segments_split[segments_split$id==id,]
    
  output_s_s_c$segments <- bind_rows(output_s_s_c$segments,segments)
  
  # Stat cont.
  stat_cont <- data.frame(
    id = output_s_s_c$segments$id,
    de = calc_segment(cont,as.numeric(segments$start_de),as.numeric(segments$end_de),analysis),
    t =  calc_segment(cont,as.numeric(segments$start_t), as.numeric(segments$end_t),analysis),
    pe = calc_segment(cont,as.numeric(segments$start_pe),as.numeric(segments$end_pe),analysis))

  output_s_s_c$stat_cont <- bind_rows(output_s_s_c$stat_cont,stat_cont)

  return(output_s_s_c)
}

#split_finals <- split_contour_extractor("final")
split_contour_extractor <- function(analysis2) {
  output_split <- list()
  if (analysis2 == "final"){
    splitted_excels <-  xl$split_excel_final
    ready_to_merge <- c(2,4,6,9) # Angiver rækken for hvornår alle splittede filer er indlæst og klar til merge.
  } else if (analysis2 == "pre") {
    splitted_excels <- xl$split_excel_pre
    ready_to_merge <- 2
  }
  
  for (i in splitted_excels){
    id_curr <- sub(".*/([^/]+)_[^_/]*$", "\\1", i) #%>% print()
    id_split <- sub(".*/([^/]+)\\.xlsm$", "\\1", i)
    print(id_split)
    raw <- read_excel(path = paste0(path,i),                             
                    sheet = "OrgSheet", range = cell_limits(c(46,1),c(NA,13)),        
                    col_names = F, .name_repair = "unique_quiet")                      
    
    # Cont. Trækker offset fra hvis det er et dist eller mid run.
    cont <- extract_raw_contours(raw,id_curr) %>% 
      mutate(id_split = id_split)

    cont$frame_premerge = cont$frame # Så kan jeg se frames før korrektion.
    
    if (id_split %in% frame_offset$id_split) {
      offset <- frame_offset %>% filter(id_split2 == id_split) %>% pull(offset)
      cont$frame <- cont$frame -  offset
    }
    output_split$cont <- bind_rows(output_split$cont,cont)
  
  # Tilføjer segmenter og stat_cont efter begge excels for hver split patient er læst ind.
  if (i %in% splitted_excels[ready_to_merge]){
    merge_contours <- output_split$cont %>% filter(id == id_curr)

    output2 <- split_segments_extractor(analysis = analysis2, cont = merge_contours , id = id_curr)
    output_split$segments <- bind_rows(output_split$segments,output2$segments)
    output_split$stat_cont <- bind_rows(output_split$stat_cont,output2$stat_cont)
    }
  }

  return(output_split)
}
# analysis2; analysis; merge_contours
# split_segments_extractor(analysis = analysis2, cont = merge_contours , id = id_curr)


# output <- split_contour_extractor("final")
# output <- split_contour_extractor("pre")

# ggplot(output$cont,aes(x = frame, y = l_a, col = id)) +
#   geom_point(size = 2) +
#   geom_line(size = 1) +
#   facet_wrap(~id)

# Plaque.
plaque_split_extractor <- function() {
  paths <- xl$split_excel_pre
  output_split <- list(plaque_df = data.frame(), calc_thick_df = data.frame()) 
  
  for (i in paths){
    id_curr <- sub(".*/([^/]+)_[^_/]*$", "\\1", i)
    id_split <- sub(".*/([^/]+)\\.xlsm$", "\\1", i)
    print(id_split)
    
    d_raw <- read_excel(paste0(path,i), sheet = "OCTresults", col_names = c("desc","frame_col","value","var","dummy"))
    
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
    
    for (i in frame_intervaller$interval_nummer){
      # Subsetter data for hvert frame interval
      frame_data <- d[c(frame_intervaller$start[i]:frame_intervaller$end[i]),] # Data for hvert frame (defineret ud fra rækkeinterval)
      frame <- as.numeric(frame_data$frame_col[1])
      
      # EXTRACTER PLAQUE VINKLER FOR HVERT FRAME
      if ("Angle" %in% frame_data$value) { 
        
        # Finder start og slut række (row_raw) for plaquevinklerne
        start_row_raw <- as.numeric(frame_data %>% filter(value == "Angle") %>% pull(row_raw) + 1)  # row_raw for rækken efter "Angle"
        end_row_raw   <- as.numeric(max(frame_data$row_raw))                                          # row_raw for rækken sidst i datasættet (vinkler slutter altid til sidst i datasættet)
        
        # Midlertidigt datasæt for plaquevinkler.
        temp_data <- frame_data %>%
          filter(row_raw %in% start_row_raw:end_row_raw) %>% 
          mutate(frame = frame, id = id_curr, id_split = id_split)
        
        output_split$plaque_df <- bind_rows(output_split$plaque_df,temp_data)
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
                 frame = as.numeric(frame),
                 id = id_curr, id_split = id_split)
        
        output_split$calc_thick_df <- bind_rows(output_split$calc_thick_df,temp_data)
        
      }
        # Offsetter frames på distal med 135
      }
        if (id_split == "xxx_pre_dist") {
          offset = 135
          output_split$calc_thick_df$frame_premerge <- output_split$calc_thick_df$frame
          output_split$calc_thick_df$frame <- as.numeric(output_split$calc_thick_df$frame)
          output_split$calc_thick_df$frame <- output_split$calc_thick_df$frame - offset
          output_split$plaque_df$frame_premerge <- output_split$plaque_df$frame
          output_split$plaque_df$frame <- as.numeric(output_split$plaque_df$frame)
          output_split$plaque_df$frame <- output_split$plaque_df$frame - offset
          }
  }
  output_combined <- bind_rows(output_split$calc_thick_df,output_split$plaque_df) %>% 
    mutate(value = as.numeric(value)) %>% 
    select(id,value,var,frame,frame_premerge) 

  # Konklusion
  return(output_combined)
}
