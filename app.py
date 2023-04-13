from flask import Flask, request, jsonify
import json
from imessage_reader import fetch_data
from dotenv import load_dotenv
import os
import openai

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

    # Convert messages to text string
    prompt = ''
    for message in messages:
        if message['fromMe']:
            prompt += 'Me: '
        else:
            prompt += 'Them: '
        prompt += message['text'] + '\n'
    prompt += "Me: " + "\n\n###\n\n"

    response = openai.Completion.create(
        model="davinci:ft-personal-2023-04-11-08-35-06",
        prompt=prompt,
        max_tokens=50,
        stop="###",
        temperature=0.8,
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
