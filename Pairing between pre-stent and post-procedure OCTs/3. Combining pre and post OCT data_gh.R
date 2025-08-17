matcher_9000 <- function(idx) {
  # Analyserede frames
  pre_df           <- frames(idx)$pre_frames                                     # Alle analyserede frames i target på pre
  final_df         <- frames(idx)$final_frames                                   # Alle analyserede frames i target på final
  available_finals <- final_df$frame_final                                       # Tilgængelige final frames. Reduceres i takt med at de matches til en pre.
  
  # Her lagres umatchede (uparrede) pre-frames.
  unmatched_pre <- data.frame(x = integer(), y = integer(), dist = integer())    
  
  # Patientens matchtabel
  match_df_raw <- output_match %>%                                            
    filter(id == idx)
  
  # Finder alle de pre-frames som er analyseret men som ikke er i matchtabellen - disse matches skal tilføjes manuelt.
  pre_not_in_match <- setdiff(pre_df$frame_pre,match_df_raw$pre)                 
  
  # Hvis der er analyserede pre-frames som mangler i matchtabellen, så findes et final-match på det forrige præ-frame. 
  if (length(pre_not_in_match) > 0) { 
    for (i in pre_not_in_match) {                                                # Tilføjer pre-frames som mangler, sætter ideal match til samme ideal som det tidligere frame.
      get_previous_final_match <- match_df_raw %>% 
        filter(pre == i - 1) %>% 
        pull(final)
      # Hvis der ikke var et final match, så går den et præ frame længere tilbage.
      if (length(get_previous_final_match) == 0) {                               # Hvis ikke den kan finde et match i det tidligere frame, går yderligere 1 frame tilbage. Uklart om dette trin bidrager, men er lavet for en sikkerhedsskyld.
        get_previous_final_match <- match_df_raw %>%
          filter(pre == i - 2) %>%
          pull(final)
      }
      # De manglende præ-frames tilføjes til matchtabellen med deres nyt match.
      if (length(get_previous_final_match) > 0) {                                
        match_df_raw <- bind_rows(match_df_raw,
                                  data.frame(pre = i,id = idx,
                                             final = get_previous_final_match,
                                             not_in_matchtable = T)) %>% arrange(pre)
      } else {                                                                   
        unmatched_pre <- rbind(unmatched_pre, data.frame(x = i, y = 1, dist = match$dist[i])) # Hvis ikke den kan finde en præ-frame så matches den ikke.
      }
    }
  }
  
  # Filtrerer matchtabellen til de pre-frames som skal matches (fjerer de præ-frames som ikke er analyseret)
  match <- match_df_raw %>% 
    filter(pre %in% pre_df$frame_pre) %>% 
    mutate(final_actual = NA_integer_, dist = NA_integer_)
  
  # Bestemmer tolerancen
  pbs_final_val <- d %>% filter(id == idx) %>% pull(pbs_final)
  pbs_pre_val   <- d %>% filter(id == idx) %>% pull(pbs_pre)
  
  # Looper over hver præ-frame i matchtabellen og bestemmer afstand til idelle match
  for (i in 1:nrow(match)){
    pre_current <- match$pre[i]                     # Pre-frame som aktuelt matches (analyserede præ-frames)
    final_ideal <- match$final[i]                   # Det idelle finale frame
    
    if (length(available_finals) == 0) {            # Hvis der ikke er flere final frames tilbage at matche med, så stoppes loopet.
      unmatched_pre <- rbind(unmatched_pre, data.frame(x = pre_current, y = 1, dist = NA))
      break
    }    
    # Finder det nærmeste match 
    diffs    <- abs(final_ideal - available_finals) # Beregner afstand mellem det idelle match og de tilgængelige matches.
    closest  <- which.min(diffs)                    # index for den tætteste. Returnerer max 1 værdi.
    dist_abs <- diffs[closest]                      # Afstanden til den tætteste.
    
    if (dist_abs <= ifelse(pbs_pre_val < 30,5,3)) { # Hvis afstanden er under tolerancen, så sker matchet (der er 1 med pre_pbs 25, table(d$pbs_pre))
      match$final_actual[i] <- available_finals[closest]
      match$dist[i] <- available_finals[closest] - final_ideal
      available_finals <- available_finals[-closest] 
      
    } else { 
      match$final_actual[i] <- NA_integer_
      match$dist[i] <- available_finals[closest] - final_ideal
      unmatched_pre <- rbind(unmatched_pre, data.frame(x = pre_current, y = 1, dist = match$dist[i]))
    }
  }
  
  return(list(
    match = match,                                                                    # De matchede par
    no_frames = data.frame(pre = nrow(pre_df),final = nrow(final_df)),                # Antal frames analyseret i QCU totalt
    unmatched_pres = unmatched_pre,                                                   # Oversigt over unmatched pres
    unmatched_finals = data.frame(x = available_finals,                               # Oversigt over unmatched finals
                                  y = rep(0, length(available_finals)),
                                  dist = rep(NA_integer_, length(available_finals))), 
    pre_not_in_matchtable = match %>% filter(not_in_matchtable==T),                   # Oversigt over pre-frames som blev matchet men ikke var i matchtabellen.
    pbs = data.frame(pre = pbs_pre_val,final = pbs_final_val),                        # Pullback speeds
    target_visibility = data.frame(pre = d %>% filter(id == idx) %>% pull(qcu_prs_t), # Var target analyserbar
                                   final = d %>% filter(id == idx) %>% pull(qcu_pos_t))
  ))
}

plot_matching <- function(idx,idx_split = NA,pbs_final,pbs_pre, show_output = T) {
  result <- matcher_9000(idx)     # Standard
  
  match_df <- result$match
  unmatch_df <- rbind(result$unmatched_finals,
                      result$unmatched_pres) 
  
  match_long <- match_df %>%
    select(pre, final_actual, dist) %>%
    pivot_longer(cols = c(pre, final_actual),
                 names_to = "type",
                 values_to = "frame") %>%
    mutate(y = ifelse(type == "pre", 1, 0)) %>% 
    arrange(frame)
  
  plot <- ggplot() +
    geom_segment(data = match_df,aes(x = pre, xend = final_actual, y = 1, yend = 0, color = dist), linewidth = 2) +
    geom_point(data = match_long,aes(x = frame, y = y), size = 2) +
    scale_y_continuous(breaks = c(0, 1), labels = c(paste0("Final\npbs",result$pbs$final,"\n",result$target_visibility$final), paste0("Pre\npbs",result$pbs$pre,"\n",result$target_visibility$pre))) +
    scale_color_gradient2(low = "purple", mid = "green", high = "orange", midpoint = 0, limits = c(ifelse(result$pbs$pre < 30,-5,-3),ifelse(result$pbs$pre < 30,5,3))) +
    labs(x = "Frame", y = NULL, color = "Distance from \nideal final to\nclosest final match") +
    theme_minimal() +
    theme(panel.background = element_rect(fill = "white"))
  

  if (nrow(unmatch_df > 0)) {
    plot <- plot +
      geom_point(data = unmatch_df,aes(x = x, y = y), color = "red", size = 5) +
      geom_text(data = unmatch_df,
                aes(x = x, y = y, label = dist), color = "black", size = 3, vjust = -1)
  }
  
  # Plot titles
 if (idx %in% edge_cases) {
    plot <- plot +
      ggtitle(paste0(idx_split," (edge case)\ntolerance = ",ifelse(result$pbs$pre < 30,5,3)))
  } else {
    plot <- plot + 
      ggtitle(paste0(idx,"\ntolerance = ",ifelse(result$pbs$pre < 30,5,3)))
  }
  
  if (show_output == T) {
    print(result)
    print(plot)
  }
  
  return(list(plot = plot,result = result))
}
