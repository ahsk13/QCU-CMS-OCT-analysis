# Antal med både pre og post
# d %>% count(q1_prs_corr_time)
# d %>% count(q1_pos_corr_time)

d <- d %>% 
  mutate(pre_og_post = ifelse(q1_prs_corr_time == "Yes, pre-stent" & 
                                q1_pos_corr_time %in% c("Yes, final","Yes, but early final (treated as final)"),1,0))

valid <- d %>% # Obs 1 pt. hvor target ikke kan analyseres på pre. 
  filter(pre_og_post == 1, qcu_prs_t != "No", qcu_pos_t != "No") %>% pull(id) # length(valid) 164 gyldige.

# Merger pbl fra pre og final til d.
d <- pre$pbs %>% 
  mutate(id = sub("^(.*?)_.*", "\\1", id)) %>%
  select(id,pbs_pre = pbs_val) %>% 
  merge(d, by = "id", all = T)

d <- final$pbs %>% 
  mutate(id = sub("^(.*?)_.*", "\\1", id)) %>%
  select(id,pbs_final = pbs_val) %>% 
  merge(d, by = "id", all = T)

# Returnerer dataset med frames i target på pre og final per patient
frames <- function(id_curr) {
  if (!(id_curr %in% valid)) stop("Id not eligible")
  
  id_pre = paste0(id_curr,"_pre")
  id_final = paste0(id_curr,"_final")
  
  pre_frames <- pre$cont %>%                  
    mutate(id = sub("^(.*?)_.*", "\\1", id)) %>% 
    filter(id == id_curr,
           frame >= pre$segment$start_t[pre$segments$id == id_pre], # Begrænser til target
           frame <= pre$segment$end_t[pre$segments$id == id_pre],
           !is.na(l_a)) %>%                                         # Fjerner frames uden lumen areal. Skyldes at jeg har slettet en kontur fra et frame (rækken forbliver i excel) eller hvis jge har skiftet fra analyseinterval 5 til 3 eller omvendt/eller hvis hvert 3. frame er blevet forskudt.
    arrange(frame) %>%                        
    select(id,frame_pre = frame,frame_premerge,id_split) %>% 
    distinct(frame_pre, .keep_all = T)                           # I nogle frames er duplikeret. Skyldes at QCU laver en ekstra række i excel for det frame hvis der er målt en reference inde i target.
  
  final_frames <- final$cont %>% 
    mutate(id = sub("^(.*?)_.*", "\\1", id)) %>% 
    filter(id == id_curr, 
           frame >= final$segment$start_t[final$segments$id == id_final], 
           frame <= final$segment$end_t[final$segments$id == id_final],
           !is.na(l_a)) %>% 
    arrange(frame) %>%                        
    select(id,frame_final = frame, frame_premerge,id_split) %>% 
    distinct(frame_final, .keep_all = T)                         # Som ved pre.
  
  return(list(
    pre_frames = pre_frames,
    final_frames = final_frames))
} 