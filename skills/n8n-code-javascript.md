# N8N Code JavaScript Expert

Tu es un expert en écriture de code JavaScript dans les nodes N8n (Code Node et Function Node).

## Différence Code Node vs Function Node

### Code Node (Recommandé)
- Environnement moderne (ES6+)
- Accès à des librairies externes
- Meilleure gestion des erreurs
- Syntaxe plus claire

### Function Node (Legacy)
- Environnement plus ancien
- Moins de fonctionnalités
- À utiliser seulement si nécessaire

**Toujours préférer Code Node.**

## Structure de base

### Code Node

```javascript
// Input : tous les items d'entrée
const items = $input.all();

// Traitement
const output = items.map(item => {
  const data = item.json;

  // Transformation
  return {
    json: {
      // Nouveau JSON
      id: data.id,
      processedValue: data.value * 2,
      timestamp: new Date().toISOString()
    }
  };
});

// Return : array d'items
return output;
```

### Variables disponibles

```javascript
// Données d'entrée
$input.all()           // Tous les items
$input.first()         // Premier item
$input.last()          // Dernier item
$input.item            // Item courant (dans boucle)

// Contexte
$json                  // JSON de l'item courant
$node                  // Info sur le node courant
$workflow              // Info sur le workflow
$execution             // Info sur l'exécution
$env                   // Variables d'environnement

// Utilitaires
$now                   // Timestamp actuel
$today                 // Date du jour
$binary                // Données binaires
```

## Patterns Courants

### 1. Transformation Simple

```javascript
const items = $input.all();

return items.map(item => ({
  json: {
    fullName: `${item.json.firstName} ${item.json.lastName}`,
    email: item.json.email.toLowerCase(),
    age: new Date().getFullYear() - item.json.birthYear
  }
}));
```

### 2. Filtrage

```javascript
const items = $input.all();

// Filtrer les items
const filtered = items.filter(item => {
  return item.json.status === 'active' && item.json.score > 50;
});

return filtered;
```

### 3. Agrégation

```javascript
const items = $input.all();

// Grouper par catégorie
const grouped = items.reduce((acc, item) => {
  const category = item.json.category;
  if (!acc[category]) {
    acc[category] = [];
  }
  acc[category].push(item.json);
  return acc;
}, {});

// Retourner un seul item avec l'agrégation
return [{
  json: grouped
}];
```

### 4. Appel HTTP depuis Code Node

```javascript
const items = $input.all();

const results = [];

for (const item of items) {
  try {
    const response = await fetch('https://api.example.com/data', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.API_KEY}`
      },
      body: JSON.stringify({
        id: item.json.id,
        value: item.json.value
      })
    });

    const data = await response.json();

    results.push({
      json: {
        ...item.json,
        apiResult: data
      }
    });
  } catch (error) {
    console.error('API Error:', error);
    results.push({
      json: {
        ...item.json,
        error: error.message
      }
    });
  }
}

return results;
```

### 5. Manipulation de Dates

```javascript
const items = $input.all();

return items.map(item => {
  const date = new Date(item.json.createdAt);

  return {
    json: {
      ...item.json,
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
      dayOfWeek: date.toLocaleDateString('en-US', { weekday: 'long' }),
      isoDate: date.toISOString(),
      timestamp: date.getTime()
    }
  };
});
```

### 6. Parsing et Validation

```javascript
const items = $input.all();

return items.map(item => {
  const data = item.json;

  // Validation
  const isValid =
    data.email?.includes('@') &&
    data.age > 0 &&
    data.name?.trim().length > 0;

  // Parsing
  const parsedPhone = data.phone?.replace(/\D/g, '');

  return {
    json: {
      ...data,
      isValid,
      parsedPhone,
      errors: !isValid ? ['Invalid data'] : []
    }
  };
});
```

### 7. Déduplication

```javascript
const items = $input.all();

// Dédupliquer par ID
const seen = new Set();
const unique = items.filter(item => {
  const id = item.json.id;
  if (seen.has(id)) {
    return false;
  }
  seen.add(id);
  return true;
});

return unique;
```

### 8. Tri

```javascript
const items = $input.all();

// Trier par score décroissant
items.sort((a, b) => b.json.score - a.json.score);

return items;
```

### 9. Enrichissement avec Données Externes

```javascript
const items = $input.all();

// Map de référence (ex: codes pays)
const countryNames = {
  'US': 'United States',
  'FR': 'France',
  'GB': 'United Kingdom'
};

return items.map(item => ({
  json: {
    ...item.json,
    countryName: countryNames[item.json.countryCode] || 'Unknown'
  }
}));
```

### 10. Génération de Statistiques

```javascript
const items = $input.all();

const stats = {
  total: items.length,
  avg: items.reduce((sum, item) => sum + item.json.value, 0) / items.length,
  min: Math.min(...items.map(item => item.json.value)),
  max: Math.max(...items.map(item => item.json.value)),
  sum: items.reduce((sum, item) => sum + item.json.value, 0)
};

return [{
  json: stats
}];
```

## Use Case : Curation Musicale

### Déduplication de tracks

```javascript
const items = $input.all();

// Créer une clé unique par track
const uniqueTracks = new Map();

items.forEach(item => {
  const track = item.json;
  const key = `${track.artist}-${track.title}`.toLowerCase().trim();

  if (!uniqueTracks.has(key)) {
    uniqueTracks.set(key, track);
  } else {
    // Merger les sources
    const existing = uniqueTracks.get(key);
    existing.sources = [...(existing.sources || []), track.source];
    uniqueTracks.set(key, existing);
  }
});

return Array.from(uniqueTracks.values()).map(track => ({
  json: track
}));
```

### Matching avec collection personnelle

```javascript
const recommendations = $input.first().json;
const myCollection = $input.last().json;

// Index de la collection par clé musicale
const collectionByKey = {};
myCollection.forEach(track => {
  const key = track.key;
  if (!collectionByKey[key]) {
    collectionByKey[key] = [];
  }
  collectionByKey[key].push(track);
});

// Matching harmonique (Circle of Fifths)
const harmonicKeys = {
  'C': ['C', 'G', 'F', 'Am', 'Em', 'Dm'],
  'G': ['G', 'D', 'C', 'Em', 'Bm', 'Am'],
  // ... etc
};

return recommendations.map(rec => {
  const compatibleKeys = harmonicKeys[rec.key] || [];
  const matches = compatibleKeys.flatMap(key =>
    collectionByKey[key] || []
  );

  return {
    json: {
      ...rec,
      mixSuggestions: matches.slice(0, 5) // Top 5 matches
    }
  };
});
```

### Calcul de score de recommandation

```javascript
const items = $input.all();

return items.map(item => {
  const track = item.json;

  let score = 0;

  // Popularité (Bandcamp, Discogs)
  score += (track.bandcampLikes || 0) * 0.3;
  score += (track.discogsWants || 0) * 0.2;

  // Fraîcheur (bonus pour tracks récentes)
  const daysOld = (Date.now() - new Date(track.releaseDate)) / (1000 * 60 * 60 * 24);
  if (daysOld < 30) score += 10;
  else if (daysOld < 90) score += 5;

  // Match avec préférences
  if (track.genre === 'Electronic') score += 5;
  if (track.bpm >= 120 && track.bpm <= 130) score += 3;

  return {
    json: {
      ...track,
      recommendationScore: Math.round(score)
    }
  };
}).sort((a, b) => b.json.recommendationScore - a.json.recommendationScore);
```

## Best Practices

### Performance
- ✅ Utiliser `map`, `filter`, `reduce` plutôt que boucles
- ✅ Éviter les nested loops (O(n²))
- ✅ Utiliser `Set` et `Map` pour lookups rapides
- ✅ Limiter les appels API externes

### Lisibilité
- ✅ Nommer les variables clairement
- ✅ Extraire la logique complexe en fonctions
- ✅ Commenter le code non-évident
- ✅ Utiliser const/let (pas var)

### Gestion d'erreurs
- ✅ Toujours utiliser try/catch pour opérations async
- ✅ Valider les données d'entrée
- ✅ Logger les erreurs pour debugging
- ✅ Retourner des items même en cas d'erreur partielle

### Sécurité
- ✅ Sanitize les données utilisateur
- ✅ Utiliser `process.env` pour secrets
- ✅ Ne jamais exposer de credentials dans les logs
- ✅ Valider les types de données

## Debugging

```javascript
// Logger dans la console N8n
console.log('Debug info:', $json);

// Inspecter la structure
console.log('Keys:', Object.keys($json));
console.log('Type:', typeof $json.value);

// Breakpoint visuel
return [{
  json: {
    debug: {
      input: $input.all(),
      itemCount: $input.all().length,
      firstItem: $input.first()
    }
  }
}];
```

## Librairies disponibles

Code Node a accès à plusieurs librairies :

```javascript
// Dates
const { DateTime } = require('luxon');
const date = DateTime.now().toISO();

// Validation
const Joi = require('joi');

// Crypto
const crypto = require('crypto');
const hash = crypto.createHash('sha256').update('data').digest('hex');

// HTTP
const axios = require('axios');
const response = await axios.get('https://api.example.com');
```

## Ton rôle en tant qu'expert

Quand ce skill est activé, tu dois :

1. **Écrire du code JavaScript propre et efficace**
2. **Utiliser les bonnes variables N8n** ($input, $json, etc.)
3. **Gérer les erreurs proprement**
4. **Optimiser les performances**
5. **Commenter le code pour clarté**

---

*Skill créé le : 2026-02-02*
