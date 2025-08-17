import keyboard, pandas as pd,pyautogui, pygetwindow as gw
from ocr_functions import correct_position_of_oct_analysis_window, show_message_when_fail, window_is_opened
pd.set_option('display.max_rows', None)

# Initialiserer tælledictionary
counters2 = {
    "add_strut_counter": 0,
    "add_area_counter": 0
}

keyboard.add_hotkey('shift+a', lambda: add_strut())
x_strut, y_strut = None, None
def add_strut():
    if not window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"add_strut"):
        return
    curr_x, curr_y = pyautogui.position()
    correct_position_of_oct_analysis_window("strut")

    global counters2
    counters2["add_strut_counter"] +=1 
    pyautogui.moveTo(curr_x,curr_y)

keyboard.add_hotkey('shift+s', lambda: add_stent_area())
def add_stent_area():
    if not window_is_opened(["OCT Analysis Dialog","QCU-CMS"],"add_stent_area"):
        return
    curr_x, curr_y = pyautogui.position()
    correct_position_of_oct_analysis_window("stent")
    
    global counters2
    counters2["add_area_counter"] +=1 
    pyautogui.moveTo(curr_x,curr_y)



