
print("Booting engine...")

import keyboard
from init_analysis import auto_settings
from add_angle import (add_angle,add_angle2,assign_plaque_type_embnc,assign_plaque_type_embc,
    assign_plaque_type_diss,assign_plaque_type_oth,assign_plaque_type_pronc,
    counters)
from add_strut_area import (add_strut,add_stent_area,counters2)
from ocr_functions import show_warning

# SETTINGS: shift+7 
# ADD ANGLE: Alt+1, Alt+2
# ASSIGN PLAQUE: shift+ 1 = EMBNC, 2 = EMBC, 3 = DISS, 4 = OTH, 5 = PRONC.
# STENT: shift+a = add strut, shift+s = add contour)

keyboard.wait("Esc")
show_warning("Script ended","red",400)

print("Angle detections tally:")
for var, value in counters.items():
    print(f"{var}: {value}")

print("Stent detections tally:")
for var, value in counters2.items():
    print(f"{var}: {value}")
 