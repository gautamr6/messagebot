# messagebot
AI assistant to send texts on iMessages in your voice

Create a `.env` file with your OpenAI API key.

To generate the data, run
```
python generate_fine_tune_data.py
```

To fine tune the model, run
```
openai api fine_tunes.create -t data.jsonl -m davinci
```

Use the online playground to test the fine tuned model.
