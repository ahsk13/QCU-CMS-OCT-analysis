# Extracter data fra OCT analyse som er lavet i Radiant (OCT var DICOM som ikke kunne læses i QCU)

#xl$radiant # Kun xxx final og pre.

# Obs vi har ikke diameter på radiant cases.
# Obs alle konturer er i target.

# FINAL
# Konturer
final_radiant_xxx_full <- function(analysis = "final") {
  final_radiant_xxx_cont <- read_excel(path = paste0(path, grep("final", xl$radiant, value = T)),
                                        .name_repair = "unique_quiet") %>%
    select(1:3) %>%
    mutate(id = "xxx_final", 
           l_a = la_cm2 * 100, s_a = sa_cm2 * 100, 
           l_avg_d = NA, l_mi_d = NA, l_ma_d = NA, s_avg_d = NA, s_mi_d = NA, s_ma_d = NA) %>% 
    select(id,frame,l_a, l_avg_d, l_mi_d, l_ma_d,s_a,s_avg_d,s_mi_d,s_ma_d)  # Fjerner cm2 konturvariablerne og får output til at ligne de vanlige kontur dataframes.
  
  # Segmenter
  final_radiant_xxx_segments <- data.frame(
    id = "xxx_final",
    start_t = 1, end_t = 270, length_mm_t = 54, # Kun ½ af frames er eksporteret men kan se i radiant at pullback length er 54mm.
    start_de = NA, end_de = NA, length_mm_de = NA, start_pe = NA, end_pe = NA, length_mm_pe = NA)
  
  # Stat cont.
  final_radiant_xxx_stat_cont <- data.frame(
    id = "xxx_final",
    de = calc_segment(final_radiant_xxx_cont,as.numeric(final_radiant_xxx_segments$start_de),as.numeric(final_radiant_xxx_segments$end_de),analysis),
    t =  calc_segment(final_radiant_xxx_cont,as.numeric(final_radiant_xxx_segments$start_t), as.numeric(final_radiant_xxx_segments$end_t),analysis),
    pe = calc_segment(final_radiant_xxx_cont,as.numeric(final_radiant_xxx_segments$start_pe),as.numeric(final_radiant_xxx_segments$end_pe),analysis))
  
  print("xxx_final (radiant)")
  return(list(cont = final_radiant_xxx_cont,
              segments = final_radiant_xxx_segments,
              stat_cont = final_radiant_xxx_stat_cont))
}

# PRE
pre_radiant_xxx_full <- function(analysis = "pre") {
  pre_radiant_xxx <- read_excel(path = paste0(path, grep("pre", xl$radiant, value = T)),
                                 .name_repair = "unique_quiet") %>%
    mutate(l_a = la_cm2 * 100, id = "xxx_pre") %>%
    select(frame, l_a, names(.), -c("la_cm2", "...9", "...10"))
  
  pre_radiant_xxx_cont <- pre_radiant_xxx %>%
    select(id, frame, l_a) %>% 
    mutate(l_avg_d = NA, l_mi_d = NA, l_ma_d = NA, s_a = NA,s_avg_d = NA, s_mi_d = NA, s_ma_d = NA) %>% 
    select(id,frame,l_a, l_avg_d, l_mi_d, l_ma_d,s_a,s_avg_d,s_mi_d,s_ma_d)
  
  pre_radiant_xxx_segments <- data.frame(
    id = "xxx_pre",start_t = 1, end_t = 270, length_mm_t = 54,
    start_de = NA, end_de = NA, length_mm_de = NA, start_pe = NA, end_pe = NA, length_mm_pe = NA)

  pre_radiant_xxx_stat_cont <- data.frame(
    id = "xxx_pre",
    de = calc_segment(pre_radiant_xxx_cont,as.numeric(pre_radiant_xxx_segments$start_de),as.numeric(pre_radiant_xxx_segments$end_de),analysis),
    t =  calc_segment(pre_radiant_xxx_cont,as.numeric(pre_radiant_xxx_segments$start_t), as.numeric(pre_radiant_xxx_segments$end_t),analysis),
    pe = calc_segment(pre_radiant_xxx_cont,as.numeric(pre_radiant_xxx_segments$start_pe),as.numeric(pre_radiant_xxx_segments$end_pe),analysis))
  
  print("xxx_pre (radiant)")
  return(list(cont = pre_radiant_xxx_cont,
              segments = pre_radiant_xxx_segments,
              stat_cont = pre_radiant_xxx_stat_cont))
}  

plaque_radiant_xxx <- function() {
  pre_radiant_xxx <- read_excel(path = paste0(path, grep("pre", xl$radiant, value = T)),
                                 .name_repair = "unique_quiet") %>%
    mutate(l_a = la_cm2 * 100, id = "xxx_pre") %>%
    select(frame, l_a, names(.), -c("la_cm2", "...9", "...10"))
  
  pre_radiant_xxx_plaque <- pre_radiant_xxx %>%
    select(-l_a) %>%
    pivot_longer(., names_to = "var", values_to = "value", cols = c(2:7)) %>%
    filter(!is.na(value)) %>% 
    select(id,value,var,frame)
  print("xxx_pre (radiant)")
  
  return(pre_radiant_xxx_plaque)
}
