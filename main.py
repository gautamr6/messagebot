from imessage_reader import fetch_data
from dotenv import load_dotenv
import os
import openai

load_dotenv()

# con = sqlite3.connect("chat.db")
# cur = con.cursor()

# res = cur.execute("PRAGMA table_info(message)")
# print(res.fetchall())

# Create a FetchData instance
fd = fetch_data.FetchData()

# Store messages in my_data
# This is a list of tuples containing user id, message and service.
# service -> iMessage or SMS
messages = fd.get_messages()

window_size = 10
number = "+14086019615"

person_messages = [x for x in messages if x[0] == number]
sample = "What should my next message be after the conversation below?\n"
# sample = ""

for i in range(-1 * window_size, 0, 1):
    message = person_messages[i]
    if message[1] == None:
        continue
    sample += "Me: " if message[5] == 1 else "Them: "
    sample += message[1] + "\n"

# sample += "Me: "
print(sample)

# print(os.getenv("OPENAI_API_KEY"))
def predict(prompt):
    openai.api_key = os.getenv("OPENAI_API_KEY")
    response = openai.ChatCompletion.create(
        model = "gpt-3.5-turbo",
        messages = [{"role": "user", "content": prompt}],
        # max_tokens = 50,
    )

    print(response)

predict(sample)