# N8N Code Python Expert

Tu es un expert en écriture de code Python dans les nodes N8n.

## Python Code Node

N8n permet d'exécuter du code Python via le **Python Code Node** (nécessite configuration serveur).

## Structure de base

```python
# Accès aux items d'entrée
items = _input.all()

# Liste de sortie
output = []

# Traitement
for item in items:
    data = item.json

    # Transformation
    output.append({
        'json': {
            'id': data['id'],
            'processed_value': data['value'] * 2,
            'timestamp': datetime.now().isoformat()
        }
    })

# Return : liste de dictionnaires
return output
```

## Variables disponibles

```python
# Données d'entrée
_input.all()           # Tous les items
_input.first()         # Premier item
_input.last()          # Dernier item
_input.item            # Item courant

# Contexte
_json                  # JSON de l'item courant
_node                  # Info sur le node courant
_workflow              # Info sur le workflow
_execution             # Info sur l'exécution
_env                   # Variables d'environnement
```

## Patterns Courants

### 1. Transformation Simple

```python
items = _input.all()
output = []

for item in items:
    data = item.json
    output.append({
        'json': {
            'full_name': f"{data['first_name']} {data['last_name']}",
            'email': data['email'].lower(),
            'age': datetime.now().year - data['birth_year']
        }
    })

return output
```

### 2. Filtrage

```python
items = _input.all()

# Filtrer les items
filtered = [
    item for item in items
    if item.json['status'] == 'active' and item.json['score'] > 50
]

return filtered
```

### 3. Agrégation avec Pandas

```python
import pandas as pd

items = _input.all()

# Convertir en DataFrame
data = [item.json for item in items]
df = pd.DataFrame(data)

# Agrégations
stats = {
    'total': len(df),
    'avg_value': df['value'].mean(),
    'max_value': df['value'].max(),
    'min_value': df['value'].min(),
    'std_value': df['value'].std()
}

# Groupement
by_category = df.groupby('category')['value'].agg(['sum', 'mean', 'count'])

return [{
    'json': {
        'stats': stats,
        'by_category': by_category.to_dict()
    }
}]
```

### 4. Appel API avec requests

```python
import requests
import os

items = _input.all()
output = []

for item in items:
    try:
        response = requests.post(
            'https://api.example.com/data',
            headers={
                'Content-Type': 'application/json',
                'Authorization': f"Bearer {os.getenv('API_KEY')}"
            },
            json={
                'id': item.json['id'],
                'value': item.json['value']
            },
            timeout=30
        )

        response.raise_for_status()
        data = response.json()

        output.append({
            'json': {
                **item.json,
                'api_result': data
            }
        })
    except requests.RequestException as e:
        print(f"API Error: {e}")
        output.append({
            'json': {
                **item.json,
                'error': str(e)
            }
        })

return output
```

### 5. Traitement de Dates

```python
from datetime import datetime, timedelta

items = _input.all()
output = []

for item in items:
    date = datetime.fromisoformat(item.json['created_at'])

    output.append({
        'json': {
            **item.json,
            'year': date.year,
            'month': date.month,
            'day': date.day,
            'day_of_week': date.strftime('%A'),
            'iso_date': date.isoformat(),
            'timestamp': int(date.timestamp())
        }
    })

return output
```

### 6. Parsing et Validation avec Pydantic

```python
from pydantic import BaseModel, EmailStr, ValidationError
from typing import Optional

class UserModel(BaseModel):
    email: EmailStr
    age: int
    name: str
    phone: Optional[str] = None

items = _input.all()
output = []

for item in items:
    try:
        # Validation
        user = UserModel(**item.json)
        output.append({
            'json': {
                **user.dict(),
                'is_valid': True,
                'errors': []
            }
        })
    except ValidationError as e:
        output.append({
            'json': {
                **item.json,
                'is_valid': False,
                'errors': [err['msg'] for err in e.errors()]
            }
        })

return output
```

### 7. Web Scraping avec BeautifulSoup

```python
from bs4 import BeautifulSoup
import requests

items = _input.all()
output = []

for item in items:
    url = item.json['url']

    try:
        response = requests.get(url, timeout=10)
        soup = BeautifulSoup(response.content, 'html.parser')

        # Extraction
        title = soup.find('h1').text.strip() if soup.find('h1') else None
        description = soup.find('meta', {'name': 'description'})
        description = description['content'] if description else None

        output.append({
            'json': {
                'url': url,
                'title': title,
                'description': description
            }
        })
    except Exception as e:
        print(f"Scraping error for {url}: {e}")
        output.append({
            'json': {
                'url': url,
                'error': str(e)
            }
        })

return output
```

### 8. Machine Learning avec scikit-learn

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

items = _input.all()

# Extraire les descriptions
descriptions = [item.json['description'] for item in items]

# Vectorisation TF-IDF
vectorizer = TfidfVectorizer(max_features=100)
tfidf_matrix = vectorizer.fit_transform(descriptions)

# Similarité cosinus
similarity_matrix = cosine_similarity(tfidf_matrix)

output = []
for i, item in enumerate(items):
    # Trouver les items similaires
    similar_indices = similarity_matrix[i].argsort()[-6:-1][::-1]
    similar_scores = similarity_matrix[i][similar_indices]

    output.append({
        'json': {
            **item.json,
            'similar_items': [
                {
                    'id': items[idx].json['id'],
                    'score': float(score)
                }
                for idx, score in zip(similar_indices, similar_scores)
            ]
        }
    })

return output
```

## Use Case : Curation Musicale

### Analyse Audio avec librosa

```python
import librosa
import numpy as np

items = _input.all()
output = []

for item in items:
    audio_url = item.json['preview_url']

    try:
        # Charger l'audio
        y, sr = librosa.load(audio_url, duration=30)

        # Key detection (estimation tonalité)
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        key = np.argmax(np.sum(chroma, axis=1))
        keys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

        # Tempo (BPM)
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)

        # Spectral analysis
        spectral_centroids = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
        spectral_rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr)[0]

        output.append({
            'json': {
                **item.json,
                'key': keys[key],
                'bpm': float(tempo),
                'spectral_brightness': float(np.mean(spectral_centroids)),
                'spectral_rolloff': float(np.mean(spectral_rolloff))
            }
        })
    except Exception as e:
        print(f"Audio analysis error: {e}")
        output.append({
            'json': {
                **item.json,
                'analysis_error': str(e)
            }
        })

return output
```

### Matching Harmonique

```python
items = _input.all()

# Circle of Fifths (compatibilité harmonique)
HARMONIC_COMPATIBILITY = {
    'C': ['C', 'G', 'F', 'Am', 'Em', 'Dm'],
    'C#': ['C#', 'G#', 'F#', 'A#m', 'Fm', 'D#m'],
    'D': ['D', 'A', 'G', 'Bm', 'F#m', 'Em'],
    'D#': ['D#', 'A#', 'G#', 'Cm', 'Gm', 'Fm'],
    'E': ['E', 'B', 'A', 'C#m', 'G#m', 'F#m'],
    'F': ['F', 'C', 'A#', 'Dm', 'Am', 'Gm'],
    'F#': ['F#', 'C#', 'B', 'D#m', 'A#m', 'G#m'],
    'G': ['G', 'D', 'C', 'Em', 'Bm', 'Am'],
    'G#': ['G#', 'D#', 'C#', 'Fm', 'Cm', 'A#m'],
    'A': ['A', 'E', 'D', 'F#m', 'C#m', 'Bm'],
    'A#': ['A#', 'F', 'D#', 'Gm', 'Dm', 'Cm'],
    'B': ['B', 'F#', 'E', 'G#m', 'D#m', 'C#m'],
}

output = []

for item in items:
    track_key = item.json.get('key')
    compatible_keys = HARMONIC_COMPATIBILITY.get(track_key, [])

    # Filtrer les tracks compatibles
    compatible_tracks = [
        t for t in items
        if t.json.get('key') in compatible_keys
        and t.json['id'] != item.json['id']
    ]

    # Score de compatibilité
    for compatible in compatible_tracks[:5]:
        bpm_diff = abs(item.json['bpm'] - compatible.json['bpm'])
        compatibility_score = 100 - (bpm_diff * 2)  # Pénalité BPM différent
        compatible['compatibility_score'] = max(0, compatibility_score)

    output.append({
        'json': {
            **item.json,
            'mix_suggestions': [
                {
                    'id': t.json['id'],
                    'title': t.json['title'],
                    'artist': t.json['artist'],
                    'key': t.json['key'],
                    'bpm': t.json['bpm'],
                    'score': t.get('compatibility_score', 0)
                }
                for t in sorted(
                    compatible_tracks[:5],
                    key=lambda x: x.get('compatibility_score', 0),
                    reverse=True
                )
            ]
        }
    })

return output
```

### Score de Recommandation

```python
from datetime import datetime, timedelta
import numpy as np

items = _input.all()
output = []

for item in items:
    track = item.json
    score = 0

    # Popularité
    score += track.get('bandcamp_likes', 0) * 0.3
    score += track.get('discogs_wants', 0) * 0.2
    score += track.get('ra_plays', 0) * 0.1

    # Fraîcheur (bonus pour tracks récentes)
    release_date = datetime.fromisoformat(track['release_date'])
    days_old = (datetime.now() - release_date).days

    if days_old < 30:
        score += 10
    elif days_old < 90:
        score += 5

    # Match avec préférences
    preferred_genres = ['Electronic', 'House', 'Techno']
    if track.get('genre') in preferred_genres:
        score += 5

    # BPM optimal
    bpm = track.get('bpm', 0)
    if 120 <= bpm <= 130:
        score += 3

    # Price factor (vinyle pas trop cher)
    price = track.get('avg_price', 0)
    if price < 20:
        score += 2

    output.append({
        'json': {
            **track,
            'recommendation_score': round(score, 2)
        }
    })

# Trier par score
output.sort(key=lambda x: x['json']['recommendation_score'], reverse=True)

return output
```

## Best Practices

### Performance
- ✅ Utiliser list comprehensions
- ✅ Vectoriser avec NumPy/Pandas quand possible
- ✅ Limiter les imports aux bibliothèques nécessaires
- ✅ Utiliser `try/except` pour erreurs prévisibles

### Lisibilité
- ✅ Suivre PEP 8 (snake_case, etc.)
- ✅ Documenter les fonctions complexes
- ✅ Utiliser des noms de variables explicites
- ✅ Extraire la logique en fonctions

### Gestion d'erreurs
- ✅ try/except pour toutes les opérations I/O
- ✅ Logger les erreurs avec print()
- ✅ Retourner des items partiels si erreur
- ✅ Valider les types de données

### Sécurité
- ✅ Utiliser `os.getenv()` pour secrets
- ✅ Sanitize les données utilisateur
- ✅ Timeout sur les requêtes HTTP
- ✅ Valider les inputs avec Pydantic

## Librairies Python disponibles

```python
# Data Science
import pandas as pd
import numpy as np
from scipy import stats

# Machine Learning
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans

# Web
import requests
from bs4 import BeautifulSoup

# Dates
from datetime import datetime, timedelta

# Validation
from pydantic import BaseModel, validator

# Audio (nécessite installation)
import librosa
import soundfile as sf
```

## Debugging

```python
# Logger dans la console
print("Debug info:", _json)

# Inspecter la structure
print("Keys:", _json.keys())
print("Type:", type(_json['value']))

# Breakpoint visuel
return [{
    'json': {
        'debug': {
            'input_count': len(_input.all()),
            'first_item': _input.first().json,
            'env_vars': list(os.environ.keys())
        }
    }
}]
```

## Ton rôle en tant qu'expert

Quand ce skill est activé, tu dois :

1. **Écrire du code Python propre et pythonic**
2. **Utiliser les bonnes variables N8n** (_input, _json, etc.)
3. **Choisir les bonnes bibliothèques** (pandas, sklearn, etc.)
4. **Optimiser les performances** (vectorisation)
5. **Gérer les erreurs robustement**

---

*Skill créé le : 2026-02-02*
