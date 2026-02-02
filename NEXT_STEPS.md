# 🎯 Prochaines Étapes - Complétion du Workflow

Ce document détaille les étapes pour finaliser le workflow de curation musicale et ajouter les fonctionnalités avancées.

---

## ✅ Ce Qui Est Déjà Fait

### Infrastructure ✓
- [x] Schéma PostgreSQL complet (4 tables, 3 vues, indexes)
- [x] Guide d'installation PostgreSQL
- [x] Configuration des variables d'environnement

### Workflows de Base ✓
- [x] Workflow d'import de collection Discogs
- [x] Workflow principal avec :
  - Agrégation des 3 sources (Bandcamp, Discogs, RA)
  - Déduplication des tracks
  - Enrichissement basique (key/BPM via GetSongKey, YouTube)
  - Stockage PostgreSQL
  - Rate limiting

### Documentation ✓
- [x] README principal
- [x] Guide de démarrage rapide (QUICKSTART.md)
- [x] Plan d'implémentation détaillé
- [x] 7 skills N8n de référence

---

## 🔨 Ce Qui Reste à Implémenter

### 1. Compléter le Node de Merge d'Enrichissements

**État actuel** : Le workflow enrichit avec GetSongKey et YouTube en parallèle, mais ne merge pas correctement les résultats.

**À faire** : Ajouter un node "Code" après les nodes d'enrichissement parallèles pour fusionner les données.

```javascript
// Code Node: Merge Enrichments
const baseTrack = $node["Deduplicate Tracks"].json[$itemIndex];
const keyData = $node["Get Key and BPM"].json;
const youtubeData = $node["Search YouTube"].json;

const enrichedTrack = {
  ...baseTrack,
  key: keyData?.key || null,
  bpm: keyData?.bpm || keyData?.tempo || null,
  camelotKey: keyData?.camelot || null,
  youtubeUrl: youtubeData?.items?.[0]?.id?.videoId
    ? `https://youtube.com/watch?v=${youtubeData.items[0].id.videoId}`
    : null,
  spectralFeatures: {
    danceability: keyData?.danceability || null,
    energy: keyData?.energy || null,
    acousticness: keyData?.acousticness || null
  },
  enrichedAt: new Date().toISOString()
};

return [{json: enrichedTrack}];
```

**Position dans le workflow** : Entre "Search YouTube" et "Store in PostgreSQL"

---

### 2. Ajouter le Lookup de Prix Vinyle (Discogs Marketplace)

**État actuel** : Pas implémenté

**À faire** : Ajouter un node HTTP Request pour récupérer les prix depuis l'API Discogs Marketplace.

#### Node A : Préparer le Request
```javascript
// Code Node: Prepare Price Lookup
const track = $json;

if (track.discogsReleaseId) {
  return [{
    json: {
      ...track,
      needsPriceLookup: true
    }
  }];
}

// Si pas de release_id, on skip le price lookup
return [{
  json: {
    ...track,
    avgVinylPrice: null
  }
}];
```

#### Node B : HTTP Request Discogs Marketplace
```json
{
  "name": "Get Discogs Marketplace Price",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "=https://api.discogs.com/marketplace/stats/{{ $json.discogsReleaseId }}",
    "method": "GET",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Authorization",
          "value": "=Discogs token={{ $env.DISCOGS_API_TOKEN }}"
        },
        {
          "name": "User-Agent",
          "value": "N8nMusicCuration/1.0"
        }
      ]
    }
  },
  "continueOnFail": true
}
```

#### Node C : Parse Price
```javascript
// Code Node: Parse Price Data
const priceData = $json;

return [{
  json: {
    avgVinylPrice: priceData.lowest_price?.value || null,
    priceUpdatedAt: new Date().toISOString()
  }
}];
```

---

### 3. Implémenter l'Algorithme de Matching avec Collection Personnelle

**État actuel** : La collection est récupérée mais pas utilisée pour le matching.

**À faire** : Ajouter un node "Code" qui implémente l'algorithme de matching harmonique (Camelot Wheel).

```javascript
// Code Node: Match Personal Collection
const track = $json;
const collection = $node["Get Personal Collection"].json;

// Camelot Wheel complet pour compatibilité harmonique
const camelotWheel = {
  '1A': ['1A', '12A', '2A', '1B'],  // Ab minor
  '1B': ['1B', '12B', '2B', '1A'],  // B major
  '2A': ['2A', '1A', '3A', '2B'],   // Eb minor
  '2B': ['2B', '1B', '3B', '2A'],   // Db major
  '3A': ['3A', '2A', '4A', '3B'],   // Bb minor
  '3B': ['3B', '2B', '4B', '3A'],   // Gb major
  '4A': ['4A', '3A', '5A', '4B'],   // F minor
  '4B': ['4B', '3B', '5B', '4A'],   // Ab major
  '5A': ['5A', '4A', '6A', '5B'],   // C minor
  '5B': ['5B', '4B', '6B', '5A'],   // Eb major
  '6A': ['6A', '5A', '7A', '6B'],   // G minor
  '6B': ['6B', '5B', '7B', '6A'],   // Bb major
  '7A': ['7A', '6A', '8A', '7B'],   // D minor
  '7B': ['7B', '6B', '8B', '7A'],   // F major
  '8A': ['8A', '7A', '9A', '8B'],   // A minor
  '8B': ['8B', '7B', '9B', '8A'],   // C major
  '9A': ['9A', '8A', '10A', '9B'],  // E minor
  '9B': ['9B', '8B', '10B', '9A'],  // G major
  '10A': ['10A', '9A', '11A', '10B'], // B minor
  '10B': ['10B', '9B', '11B', '10A'], // D major
  '11A': ['11A', '10A', '12A', '11B'], // F# minor
  '11B': ['11B', '10B', '12B', '11A'], // A major
  '12A': ['12A', '11A', '1A', '12B'],  // Db minor
  '12B': ['12B', '11B', '1B', '12A']   // E major
};

// Fonction de scoring
function scoreMatch(recommendation, collectionTrack) {
  let score = 0;

  // Compatibilité harmonique (priorité maximale)
  if (recommendation.camelotKey && collectionTrack.camelot_key) {
    const compatibleKeys = camelotWheel[recommendation.camelotKey] || [];
    if (compatibleKeys.includes(collectionTrack.camelot_key)) {
      score += 10;
    }
  }

  // Matching BPM (±5% ou half/double time)
  if (recommendation.bpm && collectionTrack.bpm) {
    const bpmDiff = Math.abs(recommendation.bpm - collectionTrack.bpm);
    const halfTimeDiff = Math.abs(recommendation.bpm - collectionTrack.bpm / 2);
    const doubleTimeDiff = Math.abs(recommendation.bpm - collectionTrack.bpm * 2);

    if (bpmDiff <= 2) score += 5;
    else if (bpmDiff <= 5) score += 3;
    else if (halfTimeDiff <= 2 || doubleTimeDiff <= 2) score += 2;
  }

  // Même genre
  if (recommendation.genre === collectionTrack.genre) {
    score += 3;
  }

  // Énergie similaire (si disponible)
  if (recommendation.spectralFeatures?.energy && collectionTrack.energy) {
    const energyDiff = Math.abs(recommendation.spectralFeatures.energy - collectionTrack.energy);
    if (energyDiff <= 0.1) score += 2;
  }

  return score;
}

// Trouver les meilleurs matches
const matches = collection
  .map(collectionTrack => ({
    ...collectionTrack,
    matchScore: scoreMatch(track, collectionTrack)
  }))
  .filter(match => match.matchScore > 0)
  .sort((a, b) => b.matchScore - a.matchScore)
  .slice(0, 5);

return [{
  json: {
    ...track,
    mixSuggestions: matches.map(m => ({
      trackId: m.id,
      artist: m.artist,
      title: m.title,
      matchScore: m.matchScore,
      reason: m.matchScore >= 10 ? 'harmonic_compatible' :
              m.matchScore >= 5 ? 'bpm_match' : 'genre_match'
    }))
  }
}];
```

**Position dans le workflow** : Après "Merge Enrichments", avant "Store in PostgreSQL"

---

### 4. Enrichir la Collection Personnelle avec Key/BPM

**État actuel** : La collection importée n'a pas de `musical_key` ni `bpm`.

**À faire** : Créer un workflow séparé "Enrich Personal Collection" qui :

1. Lit les tracks de `personal_collection` où `musical_key IS NULL`
2. Pour chaque track, appelle GetSongKey API
3. Met à jour la base de données avec les résultats

#### Structure du Workflow

```
[Manual Trigger]
    ↓
[PostgreSQL: SELECT FROM personal_collection WHERE musical_key IS NULL]
    ↓
[Split Into Batches: 5]
    ↓
[HTTP Request: GetSongKey API]
    ↓
[Code: Parse Key Data]
    ↓
[PostgreSQL: UPDATE personal_collection SET musical_key, bpm, camelot_key]
    ↓
[Wait 1s]
    ↓
[Loop to next batch]
```

---

### 5. Ajouter l'Email Digest Quotidien

**État actuel** : Pas implémenté

**À faire** : Ajouter à la fin du workflow principal des nodes pour générer et envoyer un email HTML.

#### Node A : Generate Email Body
```javascript
// Code Node: Generate Email Body
const recommendations = $node["Store in PostgreSQL"].json;

const html = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .track { margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 8px; }
    .track h4 { margin: 0 0 10px 0; color: #333; }
    .track p { margin: 5px 0; color: #666; }
    .track a { color: #1DB954; text-decoration: none; }
  </style>
</head>
<body>
  <h2>🎵 Curation Musicale du ${new Date().toLocaleDateString('fr-FR')}</h2>

  <p>Voici vos <strong>${recommendations.length}</strong> nouvelles recommandations musicales :</p>

  <h3>🔥 Top Recommendations (Multi-sources)</h3>
  ${recommendations
    .filter(r => r.discoveryScore > 1)
    .slice(0, 10)
    .map(r => `
      <div class="track">
        <h4>${r.artist} - ${r.title}</h4>
        <p><strong>Sources:</strong> ${r.sources.join(', ')}</p>
        <p><strong>Key:</strong> ${r.key || 'N/A'} | <strong>BPM:</strong> ${r.bpm || 'N/A'}</p>
        ${r.youtubeUrl ? `<p><a href="${r.youtubeUrl}">🎥 Écouter sur YouTube</a></p>` : ''}
        ${r.avgVinylPrice ? `<p>💰 Prix vinyle: ${r.avgVinylPrice}€</p>` : ''}
        ${r.mixSuggestions?.length > 0 ? `
          <p><strong>🎛️ À mixer avec:</strong></p>
          <ul>
            ${r.mixSuggestions.slice(0, 3).map(s =>
              `<li>${s.artist} - ${s.title} (score: ${s.matchScore})</li>`
            ).join('')}
          </ul>
        ` : ''}
      </div>
    `).join('')}

  <h3>💎 Autres découvertes</h3>
  <ul>
    ${recommendations
      .filter(r => r.discoveryScore === 1)
      .slice(0, 20)
      .map(r => `<li><strong>${r.artist}</strong> - ${r.title} (${r.sources[0]})</li>`)
      .join('')}
  </ul>

  <p><em>Workflow exécuté avec succès à ${new Date().toLocaleTimeString('fr-FR')}</em></p>
</body>
</html>
`;

return [{
  json: {
    emailBody: html,
    subject: `🎵 ${recommendations.length} nouvelles recommandations musicales`,
    recipientEmail: process.env.ADMIN_EMAIL
  }
}];
```

#### Node B : Send Email

Utilisez le node "Send Email" de N8n :

```json
{
  "name": "Send Daily Digest",
  "type": "n8n-nodes-base.emailSend",
  "parameters": {
    "fromEmail": "noreply@n8n.cloud",
    "toEmail": "={{ $json.recipientEmail }}",
    "subject": "={{ $json.subject }}",
    "emailFormat": "html",
    "text": "={{ $json.emailBody }}"
  }
}
```

**Configuration requise** : Configurez SMTP dans N8n ou utilisez un service comme SendGrid.

---

### 6. Ajouter le Logging d'Exécution

**État actuel** : Les tables `workflow_executions` et `workflow_errors` existent mais ne sont pas utilisées.

**À faire** : Ajouter des nodes PostgreSQL pour logger les métriques.

#### Au Début du Workflow

```sql
-- Node PostgreSQL: Log Execution Start
INSERT INTO workflow_executions (workflow_id, execution_id, status, started_at)
VALUES (
  '{{ $workflow.id }}',
  '{{ $execution.id }}',
  'running',
  NOW()
)
RETURNING id;
```

#### À la Fin du Workflow (Success)

```sql
-- Node PostgreSQL: Log Execution Success
UPDATE workflow_executions
SET
  status = 'success',
  tracks_fetched = {{ $node["Deduplicate Tracks"].json.length }},
  tracks_enriched = {{ $node["Store in PostgreSQL"].json.length }},
  tracks_stored = {{ $node["Store in PostgreSQL"].json.length }},
  completed_at = NOW(),
  duration_seconds = EXTRACT(EPOCH FROM (NOW() - started_at))
WHERE execution_id = '{{ $execution.id }}';
```

#### En Cas d'Erreur (Error Trigger Workflow)

Créez un workflow séparé "Error Handler" :

```sql
INSERT INTO workflow_errors (workflow_id, execution_id, error_source, error_message, error_data)
VALUES (
  '{{ $json.workflow.id }}',
  '{{ $json.execution.id }}',
  '{{ $json.node.name }}',
  '{{ $json.error.message }}',
  '{{ JSON.stringify($json) }}'
);
```

---

### 7. Optimisations & Améliorations

#### A) Caching pour Éviter les Appels Redondants

Avant d'appeler GetSongKey ou YouTube, vérifier si on a déjà ces données :

```sql
SELECT musical_key, bpm, youtube_url
FROM music_recommendations
WHERE artist = '{{ $json.artist }}' AND title = '{{ $json.title }}'
LIMIT 1;
```

Si trouvé, réutiliser les données au lieu de faire un nouvel appel API.

#### B) Pagination pour Discogs Collection

Si votre collection Discogs > 100 items :

```javascript
// Code Node: Paginate Discogs Collection
const totalPages = Math.ceil($json.pagination.items / 100);

const pages = [];
for (let i = 1; i <= totalPages; i++) {
  pages.push({ json: { page: i } });
}

return pages;
```

Puis créer une boucle pour récupérer toutes les pages.

#### C) Conversion Musical Key → Camelot Key

Ajouter une fonction utilitaire :

```javascript
function musicalKeyToCamelot(key) {
  const mapping = {
    'C': '8B', 'Am': '8A',
    'Db': '3B', 'Bbm': '3A',
    'D': '10B', 'Bm': '10A',
    'Eb': '5B', 'Cm': '5A',
    'E': '12B', 'C#m': '12A',
    'F': '7B', 'Dm': '7A',
    'Gb': '2B', 'Ebm': '2A',
    'G': '9B', 'Em': '9A',
    'Ab': '4B', 'Fm': '4A',
    'A': '11B', 'F#m': '11A',
    'Bb': '6B', 'Gm': '6A',
    'B': '1B', 'G#m': '1A'
  };

  return mapping[key] || null;
}
```

---

## 📋 Checklist d'Implémentation

### Étape 1 : Compléter le Workflow Principal
- [ ] Ajouter node "Merge Enrichments"
- [ ] Ajouter lookup prix vinyle Discogs
- [ ] Ajouter node "Match Personal Collection" avec algorithme Camelot
- [ ] Tester le workflow complet manuellement

### Étape 2 : Enrichir la Collection
- [ ] Créer workflow "Enrich Personal Collection"
- [ ] Exécuter pour ajouter key/BPM aux tracks existantes
- [ ] Vérifier les résultats dans PostgreSQL

### Étape 3 : Automation & Monitoring
- [ ] Ajouter logging d'exécution (start/end)
- [ ] Créer workflow "Error Handler"
- [ ] Ajouter email digest
- [ ] Configurer SMTP dans N8n

### Étape 4 : Tests & Optimisations
- [ ] Tester avec quota YouTube limité
- [ ] Vérifier rate limiting Discogs (1 req/sec)
- [ ] Implémenter caching des résultats
- [ ] Optimiser les requêtes SQL

---

## 🎯 Ordre d'Implémentation Recommandé

1. **D'abord** : Enrichir votre collection personnelle (workflow séparé)
2. **Ensuite** : Compléter le merge d'enrichissements
3. **Puis** : Ajouter le matching harmonique
4. **Enfin** : Email digest et monitoring

---

## 📊 Métriques de Succès

Après implémentation complète, vous devriez avoir :

- ✅ Collection personnelle avec 80%+ de tracks enrichies (key/BPM)
- ✅ Workflow principal qui traite 30-100 tracks/jour
- ✅ Taux d'enrichissement > 70% pour les nouvelles recommendations
- ✅ Mix suggestions pour 50%+ des tracks (celles avec key/BPM)
- ✅ Email digest quotidien reçu à 6h30 (après exécution)
- ✅ < 5% d'erreurs dans `workflow_errors`

---

## 🚀 Après Complétion

Une fois tout implémenté, vous pourrez :

1. **Dashboard Vue.js** : Créer une interface web pour visualiser vos recommendations
2. **Playlists Spotify** : Auto-générer des playlists basées sur les recommendations
3. **Machine Learning** : Entraîner un modèle sur vos préférences
4. **Mobile App** : Notifications push pour les high-priority recommendations

Consultez le [plan complet](./.claude/plans/quirky-questing-zephyr.md) pour plus d'idées.

---

**Bon courage pour la suite de l'implémentation ! 🎵**
