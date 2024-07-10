with open('ascii.txt','w',encoding='utf-8') as f:
    for i in range(0, 256):
        f.write(chr(i))