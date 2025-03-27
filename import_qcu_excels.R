path = "..."

# XXX er et patient id som er anonymiseret.

# Checker først om der er adgang til D drev, derefter identificerer excel ark
if (file.exists("D:/")) {
  files0 <- list.files(path, recursive = T, 
                       pattern = "(pre|final|fu|uprs|radiant|prox|mid|dist)\\.(xls|xlsx|xlsm)$", ignore.case = T) # Filer som slutter på fu/pre//osv og ."excelfil" skal acceptere excel-formater som ikke er lavet af qcu (fx radiant)
  files <- files0[!grepl("Tidligere analyser",files0)]                                                            # Fjerner dem som ligger i "Tidligere analyser"
} else {
  stop("No access to D:/")
}

# Sorterer excelark i kategorier afh. af navn
xl <- list()

for (i in files) { 
  if (grepl("radiant",i))                                        # 2 excel (xxx) skal extractes særskilt.
    xl$radiant <- c(xl$radiant,i)                                
  else if (grepl("mid|prox|dist",i)){                            # Splittede filer
    if (grepl("final",i))
      xl$split_excel_final <- c(xl$split_excel_final,i)          ### Split final: xxx, xxx og xxx i 2/3 excels. 
    else if (grepl("pre",i))
      xl$split_excel_pre <- c(xl$split_excel_pre,i)              ### Split pre: xxx pre i 2 excels 
    else if (grepl("fu",i))
      xl$split_excel_fu <- c(xl$split_excel_fu,i)                ### Split fu: 0 pt. 
  }
  else if (grepl("\\$",i))                                       # Temporary filer er fordi de lukket forkert (skal ignoreres). kan ikke finde ud af at fixe xxx. Den korrekte fil lægger der stadig i "pre".
    xl$temporary <- c(xl$temporary,i)                            
  else if (grepl("final\\.",i))                                  # Final excels
    xl$final <- c(xl$final,i)
  else if (grepl("pre\\.",i))                                    # Pre excels Nødvendigt med \\. (finder literal "." - ellers findes der min 1. fu excel som ligger i en mappe med "pre" i)
    xl$pre <- c(xl$pre,i)
  else if (grepl("fu\\.",i))                                     # Fu excels
    xl$fu <- c(xl$fu,i)
  else if (grepl("uprs",i))
    xl$uprs <- c(xl$uprs,i)                                      # Upfront excels: Ikke systematisk analyseret fraset xxx som har en reference.
  else
    xl$oth <- c(xl$oth,i)                                        # Alt andet (tom)
}

#sapply(xl,length) # Antal excel'er i hver kategori.
#sapply(str_split(xl$final, "/"), tail, 1)