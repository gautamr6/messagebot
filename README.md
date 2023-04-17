# messagebot
Messagebot is an iMessage client for Mac that uses GPT to generate and send texts in your voice.

![](Messagebot_demo_2.gif)

## Setup

1. Create a `.env` file with your OpenAI API key.

2. To generate fine tuning data for a single conversation, run
```
python generate_fine_tune_data.py <phone_number>
```

3. To fine tune the model, run
```
openai api fine_tunes.create -t data.jsonl -m davinci
```

4. Start the flask server, providing your fine tuned model name as input:
```
python app.py <model_name>
```

5. Open the MacOS application.
