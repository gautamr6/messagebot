import json
from imessage_reader import fetch_data
from dotenv import load_dotenv
import os
import openai

# Create a FetchData instance
fd = fetch_data.FetchData()

# Store messages in my_data
# This is a list of tuples containing user id, message and service.
# service -> iMessage or SMS
messages = fd.get_messages()

window_size = 10
number = "+14086019615"

person_messages = [x for x in messages if x[0] == number and x[5] == 1]
data = []

for i in range(window_size, len(person_messages)):
    if person_messages[i][5] == 0:
        continue

    prompt = ""
    for j in range(window_size, 0, -1):
        message = person_messages[i - j]
        prompt += "Me: " if message[5] == 1 else "Them: "
        prompt += message[1] + "\n"
    prompt += "Me: " + "\n\n###\n\n"

    completion = " " + person_messages[i][1] + "###"
    data.append({"prompt": prompt, "completion": completion})

# Write data to file
with open("data.jsonl", "w") as f:
    for item in data:
        json.dump(item, f)
        f.write('\n')