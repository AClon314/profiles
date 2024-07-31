import re
import sys

def cmd_del_lines(lines: int):
    del_ascii='\x1b[1A\x1b[2K'*lines
    sys.stdout.write(del_ascii) # Move cursor up one line, Clear the entire line

def remove_html_tags(text):
    clean = re.compile('<.*?>')
    return re.sub(clean, '', text)

html = input("HTML：")
clean_text = remove_html_tags(html)

print(clean_text)