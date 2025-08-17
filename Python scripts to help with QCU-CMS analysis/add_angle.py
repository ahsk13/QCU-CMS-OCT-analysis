import pyautogui, keyboard, sys, time
from ocr_functions import add_plaque_type, find_color_yellow, find_color_blue, correct_position_of_oct_analysis_window, window_is_opened, show_warning

screen_width, screen_height = pyautogui.size()

# Initialiserer tælledictionary
counters = {
    "add_angle1_counter": 0,
    "add_angle2_counter": 0,
    "assign_plaque_type_embnc_counter": 0,
    "assign_plaque_type_embc_counter": 0,
    "assign_plaque_type_diss_counter": 0,
    "assign_plaque_type_oth_counter": 0,
    "assign_plaque_type_pronc_counter": 0
}

# Den oprindelige til add angle
#keyboard.add_hotkey('alt+1', lambda: add_angle())
#def add_angle():
#    if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"add_angle") and correct_position_of_oct_analysis_window("add_plaque"):
#        left_half = (0, 250, screen_width / 3, screen_height /2) # Koordinaterne for venstre øvre halvdel af skærmen
#        find_color_yellow(left_half,"lodret") # Finder første gule mærke (lodret arm)
#        global counters
#        counters["add_angle1_counter"] +=1
#        return

# Til at finde fractures:   
keyboard.add_hotkey('alt+1', lambda: add_angle())
def add_angle():
    if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"add_angle") and correct_position_of_oct_analysis_window("add_plaque"): # Tjekker korrekt vindue og at vinduet er korrekt placeret + klikker add angle.
        pyautogui.click(300,500) # accepterer vinklen
        found_word = True
        time.sleep(0.3) # behov for lidt delay
        found_word = find_color_blue(type = "angle",found_word = found_word) # finder og højreklikker blå. 
        add_plaque_type("FRAC")

        global counters
        counters["add_angle1_counter"] +=1
        return   
    
keyboard.add_hotkey('alt+2', lambda: add_angle2())
def add_angle2():
        if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"add_angle2") and correct_position_of_oct_analysis_window("no"):
            left_half2 = (0, 250, screen_width / 7, screen_height /1.5) # Koordinaterne for venstre øvre halvdel af skærmen
            find_color_yellow(left_half2,"vandret") # Finder andet gule mærke (venstrepegende arm)
            global counters
            counters["add_angle2_counter"] +=1
            return

keyboard.add_hotkey('shift+1', lambda: assign_plaque_type_embnc())
def assign_plaque_type_embnc():
    if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"assign_plaque_type_embnc") and correct_position_of_oct_analysis_window("assign_plaque"): # Hvis ikke placering af OCT analysis dialog er korrekt - så stop.
        found_word = True
        found_word = find_color_blue(type = "angle",found_word = found_word)
        add_plaque_type("E+NC")
        global counters
        counters["assign_plaque_type_embnc_counter"] +=1


        # Sætter length på kalk
        if found_word:
            if find_color_blue(type ="distance"): # Hvis der allerede en måling
                show_warning("Already one distance measured!","blue",300) # Hvis der allerede er en måling så laves ikke ny og warning vises.

            else: # Hvis der INGEN målinger er i forvejen - fortsæt til måling
                correct_position_of_oct_analysis_window("cal_len")
        
        pyautogui.moveTo(294, 501) # Gå til OCT katerert (er centrum i crosssectional view)


keyboard.add_hotkey('shift+2', lambda: assign_plaque_type_embc())
def assign_plaque_type_embc():
    if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"assign_plaque_type_embc") and correct_position_of_oct_analysis_window("assign_plaque"):
        found_word = True
        found_word = find_color_blue(type = "angle",found_word = found_word)

        if found_word:
            add_plaque_type("E+C")
            show_warning("CRACK","red",100)
            global counters
            counters["assign_plaque_type_embc_counter"] +=1

        # Sætter length på kalk
        if found_word:
            if find_color_blue(type = "distance"): # Hvis der allerede en måling
                show_warning("Already one distance measured!","blue",150) # Hvis der allerede er en måling så laves ikke ny og warning vises.

            else: # Hvis der INGEN målinger er i forvejen - fortsæt til måling
                correct_position_of_oct_analysis_window("cal_len") 
        
        pyautogui.moveTo(294, 501)
                 
keyboard.add_hotkey('shift+3', lambda: assign_plaque_type_diss())
def assign_plaque_type_diss():
    if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"assign_plaque_type_diss") and correct_position_of_oct_analysis_window("assign_plaque"):
        find_color_blue(type = "angle")
        add_plaque_type("D")
        global counters
        counters["assign_plaque_type_diss_counter"] +=1
        pyautogui.moveTo(294, 501)
        return

keyboard.add_hotkey('shift+4', lambda: assign_plaque_type_oth())
def assign_plaque_type_oth():
    if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"assign_plaque_type_oth") and correct_position_of_oct_analysis_window("assign_plaque"):
        find_color_blue(type = "angle")
        add_plaque_type("O")
        global counters
        counters["assign_plaque_type_oth_counter"] +=1
        return

keyboard.add_hotkey('shift+5', lambda: assign_plaque_type_pronc())
def assign_plaque_type_pronc():
    if window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"assign_plaque_type_pronc") and correct_position_of_oct_analysis_window("assign_plaque"):
        find_color_blue(type = "angle")
        add_plaque_type("P+NC")
        pyautogui.moveTo(294, 501)
        global counters
        counters["assign_plaque_type_pronc_counter"] +=1
        return







