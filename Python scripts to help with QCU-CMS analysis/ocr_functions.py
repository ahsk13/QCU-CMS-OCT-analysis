import pyautogui, pandas as pd, tkinter as tk, pytesseract, cv2, numpy as np, sys, time, pygetwindow as gw, tkinter as tk, keyboard
from tkinter import messagebox
from PIL import ImageGrab

screen_width, screen_height = 1920,1080 #pyautogui.size()
pd.set_option('display.max_rows', None)

def show_message_when_fail(title,message):
        root = tk.Tk()
        root.attributes('-topmost', True)
        root.withdraw()
        messagebox.showinfo(title,message)
        return # stopper funktionen

def capture_and_ocr(position,show_screenshot = False): # show_screenshot er True eller False.
    screenshot = ImageGrab.grab(bbox=position)
    open_cv_image = cv2.cvtColor(np.array(screenshot), cv2.COLOR_RGB2BGR)
    data = pytesseract.image_to_data(open_cv_image, output_type='data.frame')

    if show_screenshot:
        screenshot.show()
        sys.exit()  
    else:
         return data

def add_plaque_type(type):
    curr_x, curr_y = pyautogui.position()
    if type == "E+NC":
        pyautogui.click(curr_x+50,curr_y-160)
    elif type == "E+C":
        pyautogui.click(curr_x+50,curr_y-180)   
    elif type == "D":
        pyautogui.click(curr_x+50,curr_y-110)
    elif type == "P+NC":
        pyautogui.click(curr_x+50,curr_y-205)
    elif type == "FRAC": # Vælges "SB"
        pyautogui.click(curr_x+50,curr_y-45)
    elif type == "O":
        return
    return

def find_color_yellow(position,pind):
    try:
        screenshot = ImageGrab.grab(bbox = position)
        screenshot_np = np.array(screenshot)
        coordinates = []

        for y in range(screenshot_np.shape[0]):
            for x in range(screenshot_np.shape[1]):
                pixel_color = tuple(screenshot_np[y, x][:3])  # Find rgb farverne ved print(pixel_color)
                if pixel_color == (255, 255, 0):  # RGB values for yellow i tuple.
                    coordinates.append((x,y+250))

        grouped_vandret = pd.DataFrame(coordinates, columns=["X", "Y"]).groupby(["Y"])  # Grupperer således at hver y værdi samler sine x værdier i hver sin df.

        if pind == "lodret": # Lodret findes udelukkende ved at være den øverste gule pixel i venstre øvre 
            found_conseq = False
            for y in range(screenshot_np.shape[0]):
                for x in range(screenshot_np.shape[1]):
                    pixel_color = tuple(screenshot_np[y, x][:3])  # Find rgb farverne ved print(pixel_color)
                    if pixel_color == (255, 255, 0):
                        print(f"Found yellow color at coordinates: ({x}, {y+250})")
                        pyautogui.moveTo(x, y+250)
                        return  # Exit after finding the first match
            if not found_conseq:
                show_message_when_fail("Fail","gul lodret linje ikke fundet")

        if pind == "vandret":
            found_conseq = False
            for y_group_val, values in grouped_vandret: # Looper igennem y-værdi grupper og deres df.
                x_values = values["X"] # isolerer x koordinaterne i hver df

                for i in range(len(x_values)-49): # Lopper fra 0 til x_values -2 (ellers looper den udover i fordi den sammenlinger i+2)
                    if all(x_values.iloc[i + j] == x_values.iloc[i] + j for j in range(50)):
                        pyautogui.moveTo(x_values.iloc[i],y_group_val[0]) # y_group_val er tuple og vælger [0] fordi dette er groupped (y-koordinatet)
                        #print(f"Fifteen consecutive X values found for Y = {x_values.iloc[i:i+20].tolist()}: {y_group_val[0]}")

                        found_conseq = True
                        return

            if not found_conseq:
                show_message_when_fail("Fail","gul vandret linje ikke fundet")
    except KeyError:
        return
            

def find_color_blue(type,found_word = True):
    try:
        pyautogui.click(x=476,y=672) # Lukker/slipper vinklen ved at klikke et vilkårligt sted på tværsnittet.
        window_name = "OCT Analysis Dialog"
        window = gw.getWindowsWithTitle(window_name)[0] # Finder koordinater for vinduet.
        x_win, y_win = window.topleft

        # Koordinater for vinkel-kasse (der hvor alle vinkler kommer til at stå) øverste blå distance kasse
        distance_box_offset_top_x, distance_box_offset_top_y = 328, 170
        distance_box_offset_bottom_x, distance_box_offset_bottom_y = 341,180

        angle_box_offset_top_x, angle_box_offset_top_y = 328,680
        angle_box_offset_bottom_x, angle_box_offset_bottom_y = 341,800

        if type == "distance": # Koordinater for venstre øvre hjørne og højre nedre hjørne af øverste distance blå kasse
            top_left_x, top_left_y = x_win+distance_box_offset_top_x, y_win+distance_box_offset_top_y
            bottom_right_x, bottom_right_y  = x_win+distance_box_offset_bottom_x,y_win+distance_box_offset_bottom_y
   
        elif type == "angle": #Koordinater for venstre øvre hjørne og højre nedre hjørne af alle angle blå kasser
            top_left_x, top_left_y = x_win+angle_box_offset_top_x, y_win+angle_box_offset_top_y
            bottom_right_x, bottom_right_y  = x_win+angle_box_offset_bottom_x,y_win+angle_box_offset_bottom_y
        
        #time.sleep(0.2) # Behov for lille pause så blå boks kommer frem før OCR forsøger at finde den
        screenshot = ImageGrab.grab(bbox=(top_left_x,top_left_y,bottom_right_x,bottom_right_y))
        screenshot_np = np.array(screenshot)
        #screenshot.show()

        # Convert target color to a NumPy array
        target_color_np = np.array((0,255,255))  # RGB for cyan.

        mask = np.all(screenshot_np == target_color_np, axis=2)  # Checker om RGB alle passer med target_color. Axis = 2 fordi screenshot_np er et 3D array
        nonzero_indices = np.nonzero(mask) # Finder alle dem som ikker er 0
        largest_y_idx = np.argmax(nonzero_indices[0]) # Denne række har højeste y koordinat
        y, x = nonzero_indices[0][largest_y_idx], nonzero_indices[1][largest_y_idx] # x og y for højeste y koordinat
        offset_x, offset_y = 10, 10# 10/5 er offset så den kommer i midten af blå firkant.

        x_blue = top_left_x+x+offset_x
        y_blue = top_left_y+y-offset_y

        print(f"Found blue color at coordinates: ({x_blue}, {y_blue})")
        if type == "angle":
            pyautogui.click(x_blue+5,y_blue-10,button="right") # Åben plauque-vindue
        return found_word # Returnerer true hvis der er en vinkel.
    
    except ValueError: # Value error hvis den ikke finder blue.
        #show_message_when_fail("Fail","Blue square not found")
        print(f"Blue icon {type} not found")
        screenshot.show()
        found_word = False
        return found_word
    
def correct_position_of_oct_analysis_window(action):
    window_name = "OCT Analysis Dialog"
    window = gw.getWindowsWithTitle(window_name)[0] # Finder koordinater for vinduet.
    top_left_x, top_left_y = window.left, window.top # Finder y koordinatet på venstre øvre hjørne.

    # Sikrer at OCT analysis dialog er korrekt placeret
    if (action in ["stent","strut","cal_len"] and 
        (top_left_y + 515 + 60 > pyautogui.size()[1] or action == "add_plaque") and 
        (top_left_y + 715 + 80 > pyautogui.size()[1] or action == "assign_plaque") and 
        top_left_y < 70): # Hvis y koordinatet lander "under" skærmen eller svt. windows-barren (+60), så giv fejlbesked og stop funktionen.
        show_message_when_fail(f"Fail",f"'{action}' buttom outside screen")
        return False

    elif action == "stent":
        pyautogui.click(top_left_x+100,top_left_y+515) # Offset til add strut contour
    elif action == "strut":
        pyautogui.click(top_left_x+100,top_left_y+180)
    elif action == "add_plaque":
        pyautogui.click(top_left_x+100,top_left_y+750)
    elif action == "no": # Hvis ikke der er behov for at klikke.
        return True
    elif action == "cal_len":
        pyautogui.click(top_left_x+100,top_left_y+215)
    return True

def window_is_opened(allowed_windows,function):
    if gw.getActiveWindowTitle() not in allowed_windows:
        print(f"Forsøgte at køre {function}() men forkert vindue")
        return False
    return True

def power_up_the_engine():
    print("Script running")
    root = tk.Tk()
    root.geometry('50x50+1800+100')  # Place in corner, adjust as needed
    root.overrideredirect(True)  # No window border
    root.wm_attributes("-topmost", True)  # Keep on top
    root.wm_attributes("-alpha", 0.5)
    root.configure(bg='green')  # Background color as indicator
    root.bind('<Escape>', lambda e: (root.destroy(), print("Script ended"),sys.exit()))
    root.mainloop()

def show_warning(warning, color,duration):
    root = tk.Tk()
    root.geometry('370x370+400+500')  
    root.overrideredirect(True)  # No window border
    root.wm_attributes("-topmost", True)  # Keep on top
    #root.wm_attributes("-alpha", 0.5)
    root.configure(bg=color)  # Background color as indicator
    label = tk.Label(root, text=warning, font=("Arial", 16))  # Add the word "calc"
    label.pack(expand=True)
    root.after(duration, lambda: root.quit())
    root.mainloop() 
    root.destroy() # Vis vinduet, erstatter root.mainloop() - den tillod ikke at bruge flere keybinds efter den blev triggered.    


