import keyboard
from ocr_functions import show_warning

keyboard.add_hotkey('shift+o', lambda: turn_engine_on())
keyboard.add_hotkey('shift+i', lambda: check_if_engine_is_on())

keyboard.wait("Esc")

engine_on = False
def turn_engine_on():
    with open("ocr_master.py") as file:
        script_content = file.read()
        global engine_on 
        engine_on = True
    exec(script_content)

def check_if_engine_is_on():
    if engine_on:
        show_warning("It is ON!","green",1)
    else:
        show_warning("It is OFF!","red",1)
