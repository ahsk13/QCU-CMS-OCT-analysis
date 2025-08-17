# Optimizing QCU-CMS OCT core laboratory analysis
R and python scripts to assist in OCT core laboratory analysis

The following R scripts (R version 4.4.1) help with OCT datamanagement after export of excel sheets from QCU-CMS:

  0. init.R includes libraries used.

  1. import_qcu_excels.R loops over all excel file names to ensure consistency.
  
  2. cont_extractor_func.R loops over all excel sheets and extracts lumen and stent contours, segments, and calculates summary statistics for each segment. This function also handles split excels (i.e., prox excel and dist excel), and radiant analyses.

  3. Extract split excel.R loops over all split excels and extracts contours. Output of this script is fed into cont_extractor_func.R. Plaque angles are fed into plaque_extractor_func.R
     
  4. Extract radiant.R loops over all radiant excels. Output of this script is fed into cont_extractor_func.R.  Plaque angles are fed into plaque_extractor_func.R
    
  5. plaque_extractor_func.R loops over all excel sheets to extract plaque angles, plaque type, and calcium thickness. This function also handles split excels (i.e., prox excel and dist excel), and radiant analyses.  

The following python scripts help with OCT analysis in QCU-CMS:
  1. XXX

  2. XXX

Frame-by-frame pairing of pre-stent OCT and post-procedure OCT can be found in the folder "pairing between pre and post OCT"
  1. extract analyzed frames_gh.R extracts all analyzed frames on both pullbacks
  
  2. Pairing between pre and post OCT_gh.R pairs pre- and post OCT frames based on individual matching tables.

  3. Combining pre and post OCT data_gh.R combines data from different pre and post OCT datasets for a complete merged dataset (optional).


Python scripts are programmed for my PC sreen size and does not adapt to other screen sizes.



Contact: ahqxd93@hotmail.com
