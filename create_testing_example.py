import json
from imessage_reader import fetch_data
from dotenv import load_dotenv
import os
import openai

fd = fetch_data.FetchData()
messages = fd.get_messages()

window_size = 10
number = "+16465121829"

person_messages = [x for x in messages if x[0] == number]

prompt = ""
# i = len(person_messages) - 1
# while person_messages[i][5] == 0 or "<Message" in person_messages[i][1]:
#     i -= 1

i = len(person_messages) - 7

for j in range(window_size, 0, -1):
    message = person_messages[i - j]
    prompt += "Me: " if message[5] == 1 else "Them: "
    prompt += message[1] + "\n"
prompt += "Me: " + "\n\n###\n\n"

completion = " " + person_messages[i][1] + "###"

print(prompt)
print(completion)