# 🚀 Quick Start Guide - Music Curation Workflow

Ce guide vous permettra de déployer rapidement le workflow de curation musicale collaborative.

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

- ✅ Instance N8n opérationnelle : https://n8n.justsaad.fr
- ✅ PostgreSQL installé (ou accès à une instance)
- ✅ Compte Discogs avec API Token
- ⏳ YouTube Data API Key (à créer)
- ⏳ GetSongKey API Key (à créer)

---

## 📝 Étape 1 : Obtenir les API Keys Manquantes

### A) YouTube Data API Key

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet (ou sélectionnez-en un existant)
3. Activez l'API "YouTube Data API v3"
4. Créez une clé API (Credentials → Create Credentials → API Key)
5. Copiez la clé

**Quota gratuit** : 10,000 unités/jour (≈ 100 recherches)

### B) GetSongKey API (gratuit)

1. Allez sur [GetSongKey API](https://getsongkey.com/api)
2. Inscrivez-vous pour obtenir une clé gratuite
3. Notez la clé fournie

**Alternative payante** : [Soundcharts](https://soundcharts.com/) ($99+/mois) pour de meilleures détections

### C) Apify API (optionnel pour RA)

1. Allez sur [Apify](https://apify.com/)
2. Créez un compte gratuit
3. Obtenez votre API token

**Alternative** : Le workflow utilise du web scraping direct si Apify n'est pas configuré

---

## 🗄️ Étape 2 : Configurer PostgreSQL

### Option A : PostgreSQL local (macOS)

```bash
# Installer PostgreSQL
brew install postgresql@15
brew services start postgresql@15

# Créer la base de données
createdb n8n_workflows

# Exécuter le schéma
psql -d n8n_workflows -f db/schema_v1.sql
```

### Option B : PostgreSQL avec Docker

```bash
# Lancer PostgreSQL
docker run --name n8n-postgres \
  -e POSTGRES_DB=n8n_workflows \
  -e POSTGRES_USER=n8n_user \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  -d postgres:15

# Exécuter le schéma
docker exec -i n8n-postgres psql -U n8n_user -d n8n_workflows < db/schema_v1.sql
```

### Vérifier l'installation

```sql
psql -d n8n_workflows

-- Vérifier les tables
\dt

-- Devrait afficher :
-- music_recommendations
-- personal_collection
-- workflow_executions
-- workflow_errors
```

---

## ⚙️ Étape 3 : Configurer les Variables d'Environnement

Mettez à jour votre fichier [.env](.env) :

```bash
# N8n Configuration (déjà configuré)
N8N_INSTANCE_URL=https://n8n.justsaad.fr
N8N_MCP_TOKEN=<votre_token>
N8N_API_KEY=<votre_api_key>

# PostgreSQL Configuration
POSTGRES_HOST=localhost  # ou l'adresse de votre serveur
POSTGRES_PORT=5432
POSTGRES_DB=n8n_workflows
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=<votre_mot_de_passe_sécurisé>

# Discogs (déjà configuré)
DISCOGS_USERNAME=<votre_username_discogs>
DISCOGS_API_TOKEN=<votre_token_discogs>

# YouTube API
YOUTUBE_API_KEY=<votre_clé_youtube>

# GetSongKey API
GETSONGKEY_API_KEY=<votre_clé_getsongkey>

# Email Configuration
ADMIN_EMAIL=<votre_email>

# Apify (optionnel)
APIFY_API_TOKEN=<votre_token_apify>
```

---

## 🔧 Étape 4 : Importer les Workflows dans N8n

### Méthode 1 : Import via l'Interface N8n (Recommandé)

1. Connectez-vous à https://n8n.justsaad.fr
2. Cliquez sur "+" → "Import from File"
3. Importez les workflows dans cet ordre :
   - `workflows/01-import-discogs-collection.json`
   - `workflows/02-music-curation-main.json`

### Méthode 2 : Import via API

```bash
# Importer le workflow d'import Discogs
curl -X POST https://n8n.justsaad.fr/api/v1/workflows \
  -H "Authorization: Bearer $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/01-import-discogs-collection.json

# Importer le workflow principal
curl -X POST https://n8n.justsaad.fr/api/v1/workflows \
  -H "Authorization: Bearer $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/02-music-curation-main.json
```

---

## 🔑 Étape 5 : Configurer les Credentials dans N8n

Dans l'interface N8n, créez ces credentials :

### A) PostgreSQL Credentials

1. Allez dans Settings → Credentials
2. Créez "PostgreSQL account"
3. Entrez :
   - **Host** : localhost (ou l'adresse de votre serveur)
   - **Database** : n8n_workflows
   - **User** : n8n_user
   - **Password** : <votre_mot_de_passe>
   - **Port** : 5432

### B) Test de Connexion

Dans n'importe quel workflow, testez la connexion PostgreSQL en ajoutant un node PostgreSQL temporaire avec une requête simple :

```sql
SELECT 1 AS test;
```

---

## 🎵 Étape 6 : Importer votre Collection Discogs

### Exécution du Workflow d'Import

1. Ouvrez le workflow "Import Discogs Collection"
2. Vérifiez que les variables d'environnement `DISCOGS_USERNAME` et `DISCOGS_API_TOKEN` sont configurées
3. Cliquez sur "Execute Workflow"
4. Attendez que le workflow se termine

### Vérifier l'Import

```sql
-- Dans psql
SELECT COUNT(*) FROM personal_collection;

-- Afficher quelques tracks
SELECT artist, title, genre, format
FROM personal_collection
LIMIT 10;
```

**Note** : Pour le moment, les tracks importées n'auront pas de `musical_key` ou `bpm`. Vous pourrez les enrichir plus tard.

---

## 🚀 Étape 7 : Tester le Workflow Principal

### Test Manuel

1. Ouvrez le workflow "Music Curation - Complete Pipeline"
2. **Désactivez** le trigger schedule temporairement
3. Ajoutez un trigger "Manual Trigger" au début
4. Cliquez sur "Execute Workflow"
5. Surveillez l'exécution dans les logs

### Que se Passe-t-il ?

1. **Agrégation** : Récupère des tracks de Bandcamp, Discogs, et RA
2. **Déduplication** : Identifie les doublons
3. **Enrichissement** : Pour chaque track :
   - Recherche la clé musicale et BPM (GetSongKey)
   - Recherche le lien YouTube
4. **Stockage** : Sauvegarde dans PostgreSQL
5. **Rate Limiting** : Respecte les limites API (1s entre chaque batch)

### Vérifier les Résultats

```sql
-- Voir les recommandations du jour
SELECT artist, title, discovery_score, sources, musical_key, bpm, youtube_url
FROM music_recommendations
WHERE fetched_at >= CURRENT_DATE
ORDER BY discovery_score DESC
LIMIT 20;

-- Statistiques d'enrichissement
SELECT
    COUNT(*) as total,
    COUNT(musical_key) as with_key,
    COUNT(bpm) as with_bpm,
    COUNT(youtube_url) as with_youtube,
    ROUND(COUNT(musical_key)::numeric / COUNT(*)::numeric * 100, 1) as enrichment_rate
FROM music_recommendations
WHERE fetched_at >= CURRENT_DATE;
```

---

## 🔄 Étape 8 : Activer l'Automation Quotidienne

Une fois les tests réussis :

1. Ouvrez le workflow "Music Curation - Complete Pipeline"
2. Vérifiez que le Schedule Trigger est configuré : `0 6 * * *` (6h du matin)
3. **Activez** le workflow (toggle en haut à droite)
4. Le workflow s'exécutera automatiquement chaque jour à 6h

---

## 📊 Étape 9 : Consulter vos Recommandations

### Via SQL (PostgreSQL)

```sql
-- Top recommendations (multi-sources)
SELECT * FROM top_recommendations LIMIT 10;

-- Statistiques quotidiennes
SELECT * FROM recent_daily_digest;

-- Logs d'exécution
SELECT * FROM workflow_executions
ORDER BY started_at DESC
LIMIT 5;
```

### Via N8n

1. Allez dans "Executions" dans N8n
2. Consultez les logs de chaque exécution
3. Vérifiez les erreurs éventuelles

---

## 🐛 Troubleshooting

### Problème : Le workflow échoue immédiatement

**Solution** :
- Vérifiez que PostgreSQL est accessible
- Testez la connexion avec `psql -d n8n_workflows`
- Vérifiez les credentials dans N8n

### Problème : Pas de tracks récupérées de Bandcamp

**Solution** :
- Bandcamp utilise du web scraping, la structure HTML peut changer
- Vérifiez le node "Parse Bandcamp HTML" et ajustez les sélecteurs CSS si nécessaire
- Essayez d'abord manuellement : `curl https://daily.bandcamp.com/`

### Problème : YouTube quota exceeded

**Solution** :
- Vous avez dépassé les 100 recherches/jour
- Attendez 24h pour que le quota se réinitialise
- Ou supprimez temporairement le node YouTube

### Problème : GetSongKey ne trouve pas la clé

**Solution** :
- Toutes les tracks ne sont pas dans la base GetSongKey
- C'est normal que certaines tracks n'aient pas de `musical_key`
- Pour des meilleurs résultats, passez à Soundcharts (payant)

---

## 🎯 Prochaines Étapes

Maintenant que le workflow fonctionne :

1. **Enrichir votre collection** : Ajoutez `musical_key` et `bpm` à vos tracks existantes
2. **Implémenter le matching** : Ajoutez le node de matching harmonique (Camelot Wheel)
3. **Créer l'email digest** : Recevez un email quotidien avec les top recommendations
4. **Dashboard Vue.js** : Créez une interface pour visualiser vos recommendations

Consultez le [plan complet](/.claude/plans/quirky-questing-zephyr.md) pour plus de détails.

---

## 📚 Ressources

- [Documentation N8n](https://docs.n8n.io/)
- [API Discogs](https://www.discogs.com/developers/)
- [YouTube Data API](https://developers.google.com/youtube/v3)
- [GetSongKey API](https://getsongkey.com/api)
- [Camelot Wheel (Harmonic Mixing)](https://mixedinkey.com/harmonic-mixing-guide/)

---

## ✅ Checklist de Déploiement

- [ ] PostgreSQL installé et schéma créé
- [ ] API Keys obtenues (YouTube, GetSongKey)
- [ ] Variables d'environnement configurées dans `.env`
- [ ] Workflows importés dans N8n
- [ ] PostgreSQL credentials configurées dans N8n
- [ ] Collection Discogs importée
- [ ] Workflow principal testé manuellement
- [ ] Première exécution réussie
- [ ] Vérification des données dans PostgreSQL
- [ ] Automation quotidienne activée

---

**Besoin d'aide ?** Consultez le [README du projet](./README.md) ou les fichiers dans [/docs](./docs/).

Bonne curation musicale ! 🎵
