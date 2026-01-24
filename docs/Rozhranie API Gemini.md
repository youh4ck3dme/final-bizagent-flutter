> Poznámka (BizAgent): Flutter klient už priamo nevolá Gemini API. AI volania prebiehajú server-side cez Firebase Cloud Functions (`generateAiText`) a používajú OpenAI modely (primárne `gpt-4o-mini`, fallback `gpt-4o`).
>
> Tento dokument je ponechaný len ako referenčný prehľad k Gemini API a nemá byť implementačným návodom pre BizAgent klienta.

Rozhranie API Gemini
Dokumenty
Dávkové API





Rozhranie Gemini Batch API je navrhnuté na asynchrónne spracovanie veľkého objemu požiadaviek za 50 % štandardných nákladov . Cieľová doba spracovania je 24 hodín, ale vo väčšine prípadov je oveľa rýchlejšia.

Používajte rozhranie Batch API pre rozsiahle, nie urgentné úlohy, ako je predspracovanie údajov alebo spúšťanie hodnotení, kde nie je potrebná okamžitá reakcia.

Vytvorenie dávkovej úlohy
V rozhraní Batch API máte dva spôsoby, ako odoslať svoje požiadavky:

Vložené požiadavky : Zoznam GenerateContentRequestobjektov priamo zahrnutých vo vašej požiadavke na vytvorenie dávky. Toto je vhodné pre menšie dávky, ktoré udržiavajú celkovú veľkosť požiadavky pod 20 MB. Výstupom vráteným z modelu je zoznaminlineResponseobjektov.
Vstupný súbor : Súbor JSON Lines (JSONL) , kde každý riadok obsahuje kompletný GenerateContentRequestobjekt. Táto metóda sa odporúča pre väčšie požiadavky. Výstupom vráteným z modelu je súbor JSONL, kde každý riadok je buď objekt GenerateContentResponse, alebo objekt status.
Vložené požiadavky
Pre malý počet požiadaviek môžete GenerateContentRequestobjekty priamo vložiť do vášho súboru BatchGenerateContentRequest. Nasledujúci príklad volá BatchGenerateContent metódu s vloženými požiadavkami:

Python
JavaScript
ZVYŠOK


from google import genai
from google.genai import types

client = genai.Client()

# A list of dictionaries, where each is a GenerateContentRequest
inline_requests = [
    {
        'contents': [{
            'parts': [{'text': 'Tell me a one-sentence joke.'}],
            'role': 'user'
        }]
    },
    {
        'contents': [{
            'parts': [{'text': 'Why is the sky blue?'}],
            'role': 'user'
        }]
    }
]

inline_batch_job = client.batches.create(
    model="models/gemini-3-flash-preview",
    src=inline_requests,
    config={
        'display_name': "inlined-requests-job-1",
    },
)

print(f"Created batch job: {inline_batch_job.name}")
Vstupný súbor
Pre väčšie sady požiadaviek si pripravte súbor JSON Lines (JSONL). Každý riadok v tomto súbore musí byť objekt JSON obsahujúci používateľom definovaný kľúč a objekt požiadavky, kde požiadavka je platný GenerateContentRequestobjekt. Používateľom definovaný kľúč sa používa v odpovedi na označenie toho, ktorý výstup je výsledkom ktorej požiadavky. Napríklad požiadavka s kľúčom definovaným ako request-1 bude mať svoju odpoveď označenú rovnakým názvom kľúča.

Tento súbor sa nahráva pomocou rozhrania File API . Maximálna povolená veľkosť vstupného súboru je 2 GB.

Nasleduje príklad súboru JSONL. Môžete ho uložiť do súboru s názvom my-batch-requests.json:


{"key": "request-1", "request": {"contents": [{"parts": [{"text": "Describe the process of photosynthesis."}]}], "generation_config": {"temperature": 0.7}}}
{"key": "request-2", "request": {"contents": [{"parts": [{"text": "What are the main ingredients in a Margherita pizza?"}]}]}}
Podobne ako pri inline požiadavkách môžete v každom JSON požiadavky zadať ďalšie parametre, ako sú systémové inštrukcie, nástroje alebo iné konfigurácie.

Tento súbor môžete nahrať pomocou rozhrania File API , ako je znázornené v nasledujúcom príklade. Ak pracujete s multimodálnym vstupom, môžete odkazovať na iné nahrané súbory vo vašom súbore JSONL.

Python
JavaScript
ZVYŠOK


import json
from google import genai
from google.genai import types

client = genai.Client()

# Create a sample JSONL file
with open("my-batch-requests.jsonl", "w") as f:
    requests = [
        {"key": "request-1", "request": {"contents": [{"parts": [{"text": "Describe the process of photosynthesis."}]}]}},
        {"key": "request-2", "request": {"contents": [{"parts": [{"text": "What are the main ingredients in a Margherita pizza?"}]}]}}
    ]
    for req in requests:
        f.write(json.dumps(req) + "\n")

# Upload the file to the File API
uploaded_file = client.files.upload(
    file='my-batch-requests.jsonl',
    config=types.UploadFileConfig(display_name='my-batch-requests', mime_type='jsonl')
)

print(f"Uploaded file: {uploaded_file.name}")
Nasledujúci príklad volá BatchGenerateContent metódu so vstupným súborom nahraným pomocou File API:

Python
JavaScript
ZVYŠOK

from google import genai

# Assumes `uploaded_file` is the file object from the previous step
client = genai.Client()
file_batch_job = client.batches.create(
    model="gemini-3-flash-preview",
    src=uploaded_file.name,
    config={
        'display_name': "file-upload-job-1",
    },
)

print(f"Created batch job: {file_batch_job.name}")
Keď vytvoríte dávkovú úlohu, vráti sa vám názov úlohy. Tento názov použite na monitorovanie stavu úlohy, ako aj na načítanie výsledkov po jej dokončení.

Nasleduje príklad výstupu, ktorý obsahuje názov úlohy:



Created batch job from file: batches/123456789

Podpora dávkového vkladania
Na interakciu s modelom vkladania pre vyššiu priepustnosť môžete použiť rozhranie API služby Batch . Ak chcete vytvoriť dávkovú úlohu vkladania s vloženými požiadavkami alebo vstupnými súbormi , použite batches.create_embeddingsrozhranie API a zadajte model vkladania.

Python
JavaScript

from google import genai

client = genai.Client()

# Creating an embeddings batch job with an input file request:
file_job = client.batches.create_embeddings(
    model="gemini-embedding-001",
    src={'file_name': uploaded_batch_requests.name},
    config={'display_name': "Input embeddings batch"},
)

# Creating an embeddings batch job with an inline request:
batch_job = client.batches.create_embeddings(
    model="gemini-embedding-001",
    # For a predefined list of requests `inlined_requests`
    src={'inlined_requests': inlined_requests},
    config={'display_name': "Inlined embeddings batch"},
)
Ďalšie príklady nájdete v časti Vkladania v kuchárskej knihe rozhrania Batch API .

Vyžiadať konfiguráciu
Môžete zahrnúť ľubovoľné konfigurácie požiadaviek, ktoré by ste použili v štandardnej nedávkovej požiadavke. Môžete napríklad zadať teplotu, systémové inštrukcie alebo dokonca zadať iné modality. Nasledujúci príklad ukazuje príklad vloženej požiadavky, ktorá obsahuje systémovú inštrukciu pre jednu z požiadaviek:

Python
JavaScript

inline_requests_list = [
    {'contents': [{'parts': [{'text': 'Write a short poem about a cloud.'}]}]},
    {'contents': [{
        'parts': [{
            'text': 'Write a short poem about a cat.'
            }]
        }],
    'config': {
        'system_instruction': {'parts': [{'text': 'You are a cat. Your name is Neko.'}]}}
    }
]
Podobne je možné určiť nástroje, ktoré sa majú použiť pre požiadavku. Nasledujúci príklad ukazuje požiadavku, ktorá povoľuje nástroj Vyhľadávanie Google :

Python
JavaScript

inlined_requests = [
{'contents': [{'parts': [{'text': 'Who won the euro 1998?'}]}]},
{'contents': [{'parts': [{'text': 'Who won the euro 2025?'}]}],
 'config':{'tools': [{'google_search': {}}]}}]
Môžete tiež zadať štruktúrovaný výstup . Nasledujúci príklad ukazuje, ako ho zadať pre dávkové požiadavky.

Python
JavaScript

import time
from google import genai
from pydantic import BaseModel, TypeAdapter

class Recipe(BaseModel):
    recipe_name: str
    ingredients: list[str]

client = genai.Client()

# A list of dictionaries, where each is a GenerateContentRequest
inline_requests = [
    {
        'contents': [{
            'parts': [{'text': 'List a few popular cookie recipes, and include the amounts of ingredients.'}],
            'role': 'user'
        }],
        'config': {
            'response_mime_type': 'application/json',
            'response_schema': list[Recipe]
        }
    },
    {
        'contents': [{
            'parts': [{'text': 'List a few popular gluten free cookie recipes, and include the amounts of ingredients.'}],
            'role': 'user'
        }],
        'config': {
            'response_mime_type': 'application/json',
            'response_schema': list[Recipe]
        }
    }
]

inline_batch_job = client.batches.create(
    model="models/gemini-3-flash-preview",
    src=inline_requests,
    config={
        'display_name': "structured-output-job-1"
    },
)

# wait for the job to finish
job_name = inline_batch_job.name
print(f"Polling status for job: {job_name}")

while True:
    batch_job_inline = client.batches.get(name=job_name)
    if batch_job_inline.state.name in ('JOB_STATE_SUCCEEDED', 'JOB_STATE_FAILED', 'JOB_STATE_CANCELLED', 'JOB_STATE_EXPIRED'):
        break
    print(f"Job not finished. Current state: {batch_job_inline.state.name}. Waiting 30 seconds...")
    time.sleep(30)

print(f"Job finished with state: {batch_job_inline.state.name}")

# print the response
for i, inline_response in enumerate(batch_job_inline.dest.inlined_responses, start=1):
    print(f"\n--- Response {i} ---")

    # Check for a successful response
    if inline_response.response:
        # The .text property is a shortcut to the generated text.
        print(inline_response.response.text)

Nasledujúci príklad zobrazuje výstup tejto úlohy:


--- Response 1 ---
[
  {
    "recipe_name": "Chocolate Chip Cookies",
    "ingredients": [
      "1 cup (2 sticks) unsalted butter, softened",
      "3/4 cup granulated sugar",
      "3/4 cup packed light brown sugar",
      "1 large egg",
      "1 teaspoon vanilla extract",
      "2 1/4 cups all-purpose flour",
      "1 teaspoon baking soda",
      "1/2 teaspoon salt",
      "1 1/2 cups chocolate chips"
    ]
  },
  {
    "recipe_name": "Oatmeal Raisin Cookies",
    "ingredients": [
      "1 cup (2 sticks) unsalted butter, softened",
      "1 cup packed light brown sugar",
      "1/2 cup granulated sugar",
      "2 large eggs",
      "1 teaspoon vanilla extract",
      "1 1/2 cups all-purpose flour",
      "1 teaspoon baking soda",
      "1 teaspoon ground cinnamon",
      "1/2 teaspoon salt",
      "3 cups old-fashioned rolled oats",
      "1 cup raisins"
    ]
  },
  {
    "recipe_name": "Sugar Cookies",
    "ingredients": [
      "1 cup (2 sticks) unsalted butter, softened",
      "1 1/2 cups granulated sugar",
      "1 large egg",
      "1 teaspoon vanilla extract",
      "2 3/4 cups all-purpose flour",
      "1 teaspoon baking powder",
      "1/2 teaspoon salt"
    ]
  }
]

--- Response 2 ---
[
  {
    "recipe_name": "Gluten-Free Chocolate Chip Cookies",
    "ingredients": [
      "1 cup (2 sticks) unsalted butter, softened",
      "3/4 cup granulated sugar",
      "3/4 cup packed light brown sugar",
      "2 large eggs",
      "1 teaspoon vanilla extract",
      "2 1/4 cups gluten-free all-purpose flour blend (with xanthan gum)",
      "1 teaspoon baking soda",
      "1/2 teaspoon salt",
      "1 1/2 cups chocolate chips"
    ]
  },
  {
    "recipe_name": "Gluten-Free Peanut Butter Cookies",
    "ingredients": [
      "1 cup (250g) creamy peanut butter",
      "1/2 cup (100g) granulated sugar",
      "1/2 cup (100g) packed light brown sugar",
      "1 large egg",
      "1 teaspoon vanilla extract",
      "1/2 teaspoon baking soda",
      "1/4 teaspoon salt"
    ]
  },
  {
    "recipe_name": "Gluten-Free Oatmeal Raisin Cookies",
    "ingredients": [
      "1/2 cup (1 stick) unsalted butter, softened",
      "1/2 cup granulated sugar",
      "1/2 cup packed light brown sugar",
      "1 large egg",
      "1 teaspoon vanilla extract",
      "1 cup gluten-free all-purpose flour blend",
      "1/2 teaspoon baking soda",
      "1/2 teaspoon ground cinnamon",
      "1/4 teaspoon salt",
      "1 1/2 cups gluten-free rolled oats",
      "1/2 cup raisins"
    ]
  }
]
Monitorovanie stavu úlohy
Na zistenie stavu dávkovej úlohy použite názov operácie získaný pri jej vytváraní. Pole stavu dávkovej úlohy bude indikovať jej aktuálny stav. Dávková úloha môže byť v jednom z nasledujúcich stavov:

JOB_STATE_PENDINGÚloha bola vytvorená a čaká na spracovanie službou.
JOB_STATE_RUNNING: Úloha prebieha.
JOB_STATE_SUCCEEDEDÚloha bola úspešne dokončená. Teraz si môžete načítať výsledky.
JOB_STATE_FAILED: Úloha zlyhala. Ďalšie informácie nájdete v podrobnostiach o chybe.
JOB_STATE_CANCELLEDÚloha bola zrušená používateľom.
JOB_STATE_EXPIREDPlatnosť úlohy vypršala, pretože bola spustená alebo čakala na spracovanie dlhšie ako 48 hodín. Úloha nebude mať žiadne výsledky na načítanie. Môžete skúsiť úlohu odoslať znova alebo rozdeliť požiadavky do menších dávok.
Stav úlohy môžete pravidelne kontrolovať, či je dokončená.

Python
JavaScript

import time
from google import genai

client = genai.Client()

# Use the name of the job you want to check
# e.g., inline_batch_job.name from the previous step
job_name = "YOUR_BATCH_JOB_NAME"  # (e.g. 'batches/your-batch-id')
batch_job = client.batches.get(name=job_name)

completed_states = set([
    'JOB_STATE_SUCCEEDED',
    'JOB_STATE_FAILED',
    'JOB_STATE_CANCELLED',
    'JOB_STATE_EXPIRED',
])

print(f"Polling status for job: {job_name}")
batch_job = client.batches.get(name=job_name) # Initial get
while batch_job.state.name not in completed_states:
  print(f"Current state: {batch_job.state.name}")
  time.sleep(30) # Wait for 30 seconds before polling again
  batch_job = client.batches.get(name=job_name)

print(f"Job finished with state: {batch_job.state.name}")
if batch_job.state.name == 'JOB_STATE_FAILED':
    print(f"Error: {batch_job.error}")
Načítavajú sa výsledky
Keď stav úlohy indikuje, že dávková úloha bola úspešná, výsledky sú k dispozícii v responsepoli.

Python
JavaScript
ZVYŠOK

import json
from google import genai

client = genai.Client()

# Use the name of the job you want to check
# e.g., inline_batch_job.name from the previous step
job_name = "YOUR_BATCH_JOB_NAME"
batch_job = client.batches.get(name=job_name)

if batch_job.state.name == 'JOB_STATE_SUCCEEDED':

    # If batch job was created with a file
    if batch_job.dest and batch_job.dest.file_name:
        # Results are in a file
        result_file_name = batch_job.dest.file_name
        print(f"Results are in file: {result_file_name}")

        print("Downloading result file content...")
        file_content = client.files.download(file=result_file_name)
        # Process file_content (bytes) as needed
        print(file_content.decode('utf-8'))

    # If batch job was created with inline request
    # (for embeddings, use batch_job.dest.inlined_embed_content_responses)
    elif batch_job.dest and batch_job.dest.inlined_responses:
        # Results are inline
        print("Results are inline:")
        for i, inline_response in enumerate(batch_job.dest.inlined_responses):
            print(f"Response {i+1}:")
            if inline_response.response:
                # Accessing response, structure may vary.
                try:
                    print(inline_response.response.text)
                except AttributeError:
                    print(inline_response.response) # Fallback
            elif inline_response.error:
                print(f"Error: {inline_response.error}")
    else:
        print("No results found (neither file nor inline).")
else:
    print(f"Job did not succeed. Final state: {batch_job.state.name}")
    if batch_job.error:
        print(f"Error: {batch_job.error}")
Zoznam dávkových úloh
Môžete zobraziť zoznam svojich nedávnych dávkových úloh.

Python
JavaScript
ZVYŠOK

batch_jobs = client.batches.list()

# Optional query config:
# batch_jobs = client.batches.list(config={'page_size': 5})

for batch_job in batch_jobs:
    print(batch_job)
Zrušenie dávkovej úlohy
Prebiehajúcu dávkovú úlohu môžete zrušiť pomocou jej názvu. Po zrušení úlohy sa prestanú spracovávať nové požiadavky.

Python
JavaScript
ZVYŠOK

client.batches.cancel(name=batch_job_to_cancel.name)
Odstránenie dávkovej úlohy
Existujúcu dávkovú úlohu môžete odstrániť pomocou jej názvu. Po odstránení úlohy sa prestanú spracovávať nové požiadavky a odstráni sa zo zoznamu dávkových úloh.

Python
JavaScript
ZVYŠOK

client.batches.delete(name=batch_job_to_delete.name)
Dávkové generovanie obrázkov
Ak používate Gemini Nano Banana a potrebujete vygenerovať veľa obrázkov, môžete použiť rozhranie Batch API na získanie vyšších limitov rýchlosti výmenou za dodaciu lehotu až 24 hodín.

Pre malé dávky požiadaviek (menej ako 20 MB) môžete použiť buď vložené požiadavky, alebo pre veľké dávky vstupný súbor JSONL (odporúča sa na generovanie obrázkov):


Vložené požiadavky
 
Vstupný súbor

Python
JavaScript
ZVYŠOK

import json
import time
import base64
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client()

# 1. Create and upload file
file_name = "my-batch-image-requests.jsonl"
with open(file_name, "w") as f:
    requests = [
        {"key": "request-1", "request": {"contents": [{"parts": [{"text": "A big letter A surrounded by animals starting with the A letter"}]}], "generation_config": {"responseModalities": ["TEXT", "IMAGE"]}}},
        {"key": "request-2", "request": {"contents": [{"parts": [{"text": "A big letter B surrounded by animals starting with the B letter"}]}], "generation_config": {"responseModalities": ["TEXT", "IMAGE"]}}}
    ]
    for req in requests:
        f.write(json.dumps(req) + "\n")

uploaded_file = client.files.upload(
    file=file_name,
    config=types.UploadFileConfig(display_name='my-batch-image-requests', mime_type='jsonl')
)
print(f"Uploaded file: {uploaded_file.name}")

# 2. Create batch job
file_batch_job = client.batches.create(
    model="gemini-3-pro-image-preview",
    src=uploaded_file.name,
    config={
        'display_name': "file-image-upload-job-1",
    },
)
print(f"Created batch job: {file_batch_job.name}")

# 3. Monitor job status
job_name = file_batch_job.name
print(f"Polling status for job: {job_name}")

completed_states = set([
    'JOB_STATE_SUCCEEDED',
    'JOB_STATE_FAILED',
    'JOB_STATE_CANCELLED',
    'JOB_STATE_EXPIRED',
])

batch_job = client.batches.get(name=job_name) # Initial get
while batch_job.state.name not in completed_states:
  print(f"Current state: {batch_job.state.name}")
  time.sleep(10) # Wait for 10 seconds before polling again
  batch_job = client.batches.get(name=job_name)

print(f"Job finished with state: {batch_job.state.name}")

# 4. Retrieve results
if batch_job.state.name == 'JOB_STATE_SUCCEEDED':
    result_file_name = batch_job.dest.file_name
    print(f"Results are in file: {result_file_name}")
    print("Downloading result file content...")
    file_content_bytes = client.files.download(file=result_file_name)
    file_content = file_content_bytes.decode('utf-8')
    # The result file is also a JSONL file. Parse and print each line.
    for line in file_content.splitlines():
      if line:
        parsed_response = json.loads(line)
        if 'response' in parsed_response and parsed_response['response']:
            for part in parsed_response['response']['candidates'][0]['content']['parts']:
              if part.get('text'):
                print(part['text'])
              elif part.get('inlineData'):
                print(f"Image mime type: {part['inlineData']['mimeType']}")
                data = base64.b64decode(part['inlineData']['data'])
        elif 'error' in parsed_response:
            print(f"Error: {parsed_response['error']}")
elif batch_job.state.name == 'JOB_STATE_FAILED':
    print(f"Error: {batch_job.error}")
Technické detaily
Podporované modely: Rozhranie Batch API podporuje celý rad modelov Gemini. Informácie o podpore rozhrania Batch API pre jednotlivé modely nájdete na stránke Modely . Podporované spôsoby rozhrania Batch API sú rovnaké ako tie, ktoré sú podporované v interaktívnom (alebo ne-dávkovom) rozhraní API.
Cena: Používanie rozhrania API v dávkovom režime je spoplatnené 50 % štandardnej ceny interaktívneho rozhrania API pre ekvivalentný model. Podrobnosti nájdete na stránke s cenami . Podrobnosti o limitoch sadzieb pre túto funkciu nájdete na stránke s limitmi sadzieb.
Cieľ úrovne služieb (SLO): Dávkové úlohy sú navrhnuté tak, aby sa dokončili do 24 hodín. Mnohé úlohy sa môžu dokončiť oveľa rýchlejšie v závislosti od ich veľkosti a aktuálneho zaťaženia systému.
Ukladanie do vyrovnávacej pamäte: Ukladanie kontextu do vyrovnávacej pamäte je povolené pre dávkové požiadavky. Ak požiadavka vo vašej dávke vyvolá zásah do vyrovnávacej pamäte, ceny tokenov vo vyrovnávacej pamäti budú rovnaké ako pri nedávkovej prevádzke API.
Najlepšie postupy
Používajte vstupné súbory pre veľké požiadavky: Pre veľký počet požiadaviek vždy použite metódu vstupu súboru pre lepšiu spravovateľnosť a aby ste sa vyhli prekročeniu limitov veľkosti požiadavky pre BatchGenerateContent samotné volanie. Upozorňujeme, že limit veľkosti súboru na vstupný súbor je 2 GB.
Ošetrenie chýb: Po dokončení úlohy skontrolujte batchStatsfor . Ak používate výstup zo súboru, analyzujte každý riadok, aby ste skontrolovali, či ide o objekt stavu alebo , ktorý indikuje chybu pre danú požiadavku. Úplnú sadu chybových kódov nájdete v sprievodcovi riešením problémov .failedRequestCountGenerateContentResponse
Odoslať úlohy raz: Vytvorenie dávkovej úlohy nie je idempotentné. Ak odošlete tú istú požiadavku na vytvorenie dvakrát, vytvoria sa dve samostatné dávkové úlohy.
Rozdeľte veľmi veľké dávky: Cieľový čas spracovania je síce 24 hodín, ale skutočný čas spracovania sa môže líšiť v závislosti od zaťaženia systému a veľkosti úlohy. V prípade veľkých úloh zvážte ich rozdelenie na menšie dávky, ak sú potrebné medzivýsledky skôr.
Čo bude ďalej