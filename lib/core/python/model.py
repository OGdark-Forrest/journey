from google import genai
import os

client = genai.Client(api_key=os.getenv("geminiKey"))

def getModelOutput():
    interaction = client.interactions.create(
        model="gemini-3.8-flash",
        input="Explain how AI works in a few words"
    )
    return interaction.output_text