import pyautogui, keyboard, pygetwindow as gw, tkinter as tk, time
from ocr_functions import show_message_when_fail, window_is_opened

screen_width, screen_height = pyautogui.size()

def get_active_window():
    active_window = gw.getActiveWindow() # Get the position and size of the active window.
    return active_window.left, active_window.top, active_window.width, active_window.height

def move_relative_click(x, y, click=1):
    win_left, win_top, win_width, win_height = get_active_window()
    
    # Calculate the absolute coordinates
    abs_x = win_left + x
    abs_y = win_top + y
    
    pyautogui.click(abs_x, abs_y, clicks = click)

def run_length_selector():
    global run_length_interval
    root = tk.Tk()
    root.attributes('-topmost', True)
    root.title("Select Run Length")

    window_width, window_height = 200, 150
    screen_width, screen_height = root.winfo_screenwidth(), root.winfo_screenheight()
    x, y = (screen_width // 2) - (window_width // 2), (screen_height // 2) - (window_height // 2)
    root.geometry(f'{window_width}x{window_height}+{x}+{y}')

    def set_run_length(value):
        global run_length_interval
        run_length_interval = value
        root.destroy()

    tk.Button(root, text="75mm", command=lambda: set_run_length('3')).pack(pady=10)
    tk.Button(root, text="54mm", command=lambda: set_run_length('5')).pack(pady=10)
    root.mainloop()
    
keyboard.add_hotkey('shift+7', lambda: auto_settings())
def auto_settings():
    if window_is_opened("OCT Analysis Dialog","add_strut"):
        time.sleep(1)
        print("shift7 pressed")
        move_relative_click(560,134,2)
        pyautogui.typewrite("0.081")
        move_relative_click(563,193)
        move_relative_click(404,175)
        move_relative_click(563,193,2)
        pyautogui.typewrite("0.1036")
        
        run_length_selector()

        move_relative_click(554, 330, 2)  # Øverste interval
        pyautogui.typewrite(run_length_interval)
        move_relative_click(554, 388)  # Åbner popup
        move_relative_click(483, 229)  # Lukker popup

        move_relative_click(552, 386, 2)  # Nederste interval
        pyautogui.typewrite(run_length_interval)
        move_relative_click(554, 330)  # Åbner popup
        move_relative_click(483, 229)  # Lukker popup

        move_relative_click(77, 629, 2)  # Strut point

