from flask import Flask, request, jsonify
from imessage_reader import fetch_data
from dotenv import load_dotenv
import os
import openai
import sys

app = Flask(__name__)

@app.route('/get_messages', methods=['GET'])
def get_messages():
    data = request.args
    num_messages = int(data['num_messages'])
    number = data['number']
    print(number)
    
    fd = fetch_data.FetchData()
    messages = fd.get_messages()
    
    person_messages = [x for x in messages if number in x[0]][-num_messages:]
    print(person_messages)

    return jsonify(person_messages)

@app.route('/generate_message', methods=['POST'])
def generate_message():
    messages = request.get_json()
    print(messages)

    # Convert messages to text string
    prompt = ''
    for message in messages:
        if message['fromMe']:
            prompt += 'Me: '
        else:
            prompt += 'Them: '
        prompt += message['text'] + '\n'
    prompt += "Me: " + "\n\n###\n\n"

    model_name = sys.argv[1]

    openai.api_key = os.getenv("OPENAI_API_KEY")
    response = openai.Completion.create(
        model=model_name,
        prompt=prompt,
        max_tokens=50,
        stop="###",
        temperature=0.8,
        presence_penalty=-0.5
    )

    return jsonify({'text': response.choices[0].text.strip()})

@app.route('/send', methods=['POST'])
def send():
    data = request.get_json()

    text = data['text']
    to = data['to']

    command = f"""osascript<<END
    tell application "Messages"
    send "{text}" to buddy "{to}" of (service 1 whose service type is iMessage)
    end tell
    END"""

    os.system(command)
    return ('', 204)


if __name__ == '__main__':
    app.run(debug=True)
