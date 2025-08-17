    #screenshot.show()
    #sys.exit()
    #for word in data['text']:
    #    if word.strip() != "": 
    #        print(word)


    found_dash = False
    for i, word in enumerate(data['text']):
        if "-" in word.strip():
            print("'-' found")
            found_dash = True
            break

    if found_dash == False:
        print("'-' not found")
        

    
    data = data.dropna(subset = ['text'])
    data = data[data['text'] != " "]
    print(data)

    sys.exit()


