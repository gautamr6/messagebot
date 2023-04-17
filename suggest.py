from imessage_reader import fetch_data
from dotenv import load_dotenv
import os
import openai
import sys

load_dotenv()

def predict_next_message(number, window_size):
    # Create a FetchData instance
    fd = fetch_data.FetchData()

    # Store messages in my_data
    # This is a list of tuples containing user id, message and service.
    # service -> iMessage or SMS
    messages = fd.get_messages()

    person_messages = [x for x in messages if number in x[0]]
    if (window_size > len(person_messages)):
        return "Not enough messages"

    prompt = ""

    for i in range(-window_size, 0, 1):
        message = person_messages[i]
        if message[1] == None:
            continue
        prompt += "Me: " if message[5] == 1 else "Them: "
        prompt += message[1] + "\n"

    prompt += "\n###\n\n"

    openai.api_key = os.getenv("OPENAI_API_KEY")
    response = openai.Completion.create(
        model="davinci:ft-personal-2023-04-11-08-35-06",
        prompt=prompt,
        temperature=0.4,
        max_tokens=50,
        stop="###",
        presence_penalty=-0.5
    )

    return response.choices[0].text.strip()

print(predict_next_message(sys.argv[1], int(sys.argv[2])))