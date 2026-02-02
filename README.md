# 🎵 N8N Music Curation Builder

Workflow N8n sophistiqué pour la curation musicale collaborative automatisée.

## 📖 Vue d'Ensemble

Ce projet implémente un système de curation musicale qui :

- 🌐 **Agrège** des recommandations de 3 sources (Bandcamp, Discogs, Resident Advisor)
- 🔍 **Enrichit** chaque track avec des métadonnées avancées :
  - Détection de tonalité musicale (key) et BPM
  - Liens vers samples YouTube
  - Prix vinyle moyen
  - Analyse spectrale (danceability, energy, acousticness)
- 🎛️ **Match** les recommendations avec votre collection personnelle via harmonic mixing (Camelot Wheel)
- 💾 **Stocke** tout dans PostgreSQL pour analyse ultérieure
- 📧 **Envoie** un digest quotidien par email avec vos top recommendations

---

## 🚀 Quick Start

**Vous êtes pressé ?** Suivez le [QUICKSTART.md](./QUICKSTART.md) pour un déploiement rapide.

**Pour une compréhension complète :** Lisez le [plan d'implémentation](./.claude/plans/quirky-questing-zephyr.md).

---

## 📂 Structure du Projet

```
N8N-builder/
├── QUICKSTART.md           # Guide de démarrage rapide
├── README.md               # Ce fichier
├── CLAUDE.md               # Documentation projet détaillée
│
├── .env                    # Variables d'environnement (ne pas commiter)
├── .env.example            # Template pour .env
│
├── db/                     # Base de données
│   ├── README.md          # Guide PostgreSQL
│   └── schema_v1.sql      # Schéma complet (4 tables + vues)
│
├── workflows/              # Workflows N8n
│   ├── 01-import-discogs-collection.json
│   └── 02-music-curation-main.json
│
├── docs/                   # Documentation technique
│   ├── MCP_SETUP.md       # Configuration serveur MCP
│   └── MCP_TOOLS.md       # Documentation outils MCP
│
├── skills/                 # Skills N8n (guides de référence)
│   ├── n8n-workflow-patterns.md
│   ├── n8n-node-configuration.md
│   ├── n8n-code-javascript.md
│   ├── n8n-code-python.md
│   ├── n8n-expression-syntax.md
│   ├── n8n-mcp-tools-expert.md
│   └── n8n-validation-expert.md
│
└── .claude/                # Configuration Claude
    └── plans/
        └── quirky-questing-zephyr.md  # Plan d'implémentation complet
```

---

## 🎯 Fonctionnalités Implémentées

### ✅ Phase 1 : Infrastructure
- [x] Schéma PostgreSQL complet (4 tables, 3 vues, indexes)
- [x] Workflow d'import de collection Discogs
- [x] Variables d'environnement configurées
- [x] Documentation complète

### ✅ Phase 2 : Agrégation Multi-Sources
- [x] Scraping Bandcamp Daily (staff picks)
- [x] API Discogs (wantlist)
- [x] Scraping Resident Advisor Paris (événements)
- [x] Déduplication intelligente

### ✅ Phase 3 : Enrichissement
- [x] Détection de clé musicale et BPM (GetSongKey API)
- [x] Recherche YouTube automatique
- [x] Lookup prix vinyle (Discogs Marketplace)
- [x] Batch processing avec rate limiting

### ⏳ Phase 4 : Matching & Automation (À Compléter)
- [ ] Algorithme de matching harmonique (Camelot Wheel)
- [ ] Suggestions de mix avec collection personnelle
- [ ] Email digest quotidien HTML
- [ ] Dashboard Vue.js de visualisation

---

## 🛠️ Prérequis

### Logiciels
- **N8n** : Instance cloud ou self-hosted
- **PostgreSQL** : v12+ (local ou distant)
- **Node.js** : v18+ (pour Vue.js dashboard, optionnel)

### API Keys Requises

| Service | Coût | Usage | Lien |
|---------|------|-------|------|
| **Discogs API** | ✅ Gratuit | Wantlist & collection | [discogs.com/developers](https://www.discogs.com/developers/) |
| **YouTube Data API** | ✅ Gratuit (10k quota/jour) | Recherche vidéos | [console.cloud.google.com](https://console.cloud.google.com/apis/credentials) |
| **GetSongKey** | ✅ Gratuit (avec attribution) | Key detection & BPM | [getsongkey.com/api](https://getsongkey.com/api) |
| **Soundcharts** | 💰 $99+/mois (optionnel) | Key detection avancée | [soundcharts.com](https://soundcharts.com/) |
| **Apify** | ✅/💰 Gratuit puis payant | RA scraping (optionnel) | [apify.com](https://apify.com/) |

---

## 📥 Installation Rapide

### 1. Cloner et Configurer

```bash
# Cloner le projet (si applicable)
git clone <repo-url>
cd N8N-builder

# Copier le template d'environnement
cp .env.example .env

# Éditer .env avec vos credentials
nano .env
```

### 2. Setup PostgreSQL

```bash
# macOS
brew install postgresql@15
brew services start postgresql@15
createdb n8n_workflows
psql -d n8n_workflows -f db/schema_v1.sql

# Ou avec Docker
docker run --name n8n-postgres \
  -e POSTGRES_DB=n8n_workflows \
  -e POSTGRES_USER=n8n_user \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  -d postgres:15
```

Voir [db/README.md](./db/README.md) pour plus de détails.

### 3. Importer les Workflows

1. Connectez-vous à votre instance N8n
2. Importez `workflows/01-import-discogs-collection.json`
3. Importez `workflows/02-music-curation-main.json`
4. Configurez les credentials PostgreSQL

### 4. Tester

```bash
# Importer votre collection Discogs
# Dans N8n : Exécutez "Import Discogs Collection"

# Tester le workflow principal
# Dans N8n : Exécutez "Music Curation - Complete Pipeline"

# Vérifier les résultats
psql -d n8n_workflows -c "SELECT * FROM top_recommendations LIMIT 10;"
```

---

## 📊 Schéma de Base de Données

### Tables Principales

#### `music_recommendations`
Stocke toutes les recommandations avec enrichissements.

**Colonnes clés** :
- `artist`, `title` - Identification
- `sources` (JSONB) - Sources recommandant ce track
- `discovery_score` - Nombre de sources (1-3)
- `musical_key`, `camelot_key`, `bpm` - Propriétés musicales
- `youtube_url`, `avg_vinyl_price` - Enrichissements
- `mix_suggestions` (JSONB) - Suggestions de mix

#### `personal_collection`
Votre bibliothèque musicale importée depuis Discogs.

#### `workflow_executions`
Logs d'exécution pour monitoring.

#### `workflow_errors`
Erreurs détaillées pour debugging.

### Vues

- `top_recommendations` - Top 50 recommendations par score
- `recent_daily_digest` - Stats quotidiennes (7 derniers jours)
- `workflow_execution_summary` - Métriques d'exécution agrégées

---

## 🔄 Workflow Principal

### Architecture

```
[Schedule Trigger: 6am Daily]
    ↓
[Parallel Fetch]
    ├─→ [Bandcamp Scraper]
    ├─→ [Discogs Wantlist API]
    └─→ [RA Paris Events Scraper]
         ↓
    [Merge & Deduplicate]
         ↓
    [Batch Process (5 tracks/batch)]
         ↓
    [For Each Track]
         ├─→ [Get Key/BPM] (GetSongKey)
         ├─→ [Search YouTube]
         └─→ [Get Vinyl Price] (Discogs)
              ↓
         [Store in PostgreSQL]
              ↓
         [Wait 1s] (Rate Limiting)
              ↓
    [Next Batch...]
```

### Nodes Détaillés

1. **Schedule Trigger** : Cron `0 6 * * *` (6h du matin)
2. **Parallel Fetch** : 3 sources simultanées
3. **Code Nodes** : Parsing HTML (Bandcamp, RA), Déduplication
4. **HTTP Requests** : APIs Discogs, YouTube, GetSongKey
5. **PostgreSQL** : Stockage avec UPSERT
6. **Wait** : Rate limiting entre batches

---

## 🎵 Exemples de Requêtes SQL

### Voir les top recommendations

```sql
SELECT artist, title, discovery_score, sources, musical_key, bpm, youtube_url
FROM music_recommendations
WHERE fetched_at >= CURRENT_DATE
ORDER BY discovery_score DESC
LIMIT 20;
```

### Statistiques d'enrichissement

```sql
SELECT
    COUNT(*) as total,
    COUNT(musical_key) as with_key,
    COUNT(bpm) as with_bpm,
    COUNT(youtube_url) as with_youtube,
    ROUND(COUNT(musical_key)::numeric / COUNT(*)::numeric * 100, 1) as enrichment_rate
FROM music_recommendations
WHERE fetched_at >= CURRENT_DATE;
```

### Trouver des tracks compatibles harmoniquement

```sql
-- Exemple : Tracks compatibles avec C (Camelot 8A)
SELECT artist, title, musical_key, camelot_key, bpm
FROM music_recommendations
WHERE camelot_key IN ('8A', '7A', '9A', '8B')
ORDER BY discovery_score DESC;
```

---

## 🐛 Troubleshooting

### Le workflow échoue

1. **Vérifier PostgreSQL** :
   ```bash
   psql -d n8n_workflows -c "SELECT 1;"
   ```

2. **Vérifier les credentials N8n** :
   - Settings → Credentials → PostgreSQL account
   - Tester la connexion

3. **Consulter les erreurs** :
   ```sql
   SELECT * FROM workflow_errors
   WHERE created_at >= CURRENT_DATE
   ORDER BY created_at DESC;
   ```

### Bandcamp ne retourne rien

- La structure HTML peut changer
- Vérifier manuellement : `curl https://daily.bandcamp.com/`
- Ajuster les sélecteurs CSS dans le node "Parse Bandcamp HTML"

### YouTube quota exceeded

- Vous avez dépassé 100 recherches/jour
- Attendez 24h ou désactivez temporairement le node YouTube

---

## 📚 Documentation Complémentaire

- **[QUICKSTART.md](./QUICKSTART.md)** - Guide de démarrage rapide (30 min)
- **[CLAUDE.md](./CLAUDE.md)** - Documentation projet complète
- **[db/README.md](./db/README.md)** - Guide PostgreSQL détaillé
- **[Plan d'implémentation](./.claude/plans/quirky-questing-zephyr.md)** - Architecture complète

### Skills N8n (Références)

- **[n8n-workflow-patterns.md](./skills/n8n-workflow-patterns.md)** - Patterns de conception
- **[n8n-code-javascript.md](./skills/n8n-code-javascript.md)** - Code JavaScript dans N8n
- **[n8n-node-configuration.md](./skills/n8n-node-configuration.md)** - Configuration des nodes

---

## 🗺️ Roadmap

### Version 1.0 (Actuelle)
- ✅ Infrastructure PostgreSQL
- ✅ Agrégation multi-sources
- ✅ Enrichissement basique (key, BPM, YouTube)
- ⏳ Automation quotidienne

### Version 2.0 (Prochaine)
- [ ] Algorithme de matching harmonique (Camelot Wheel)
- [ ] Email digest HTML quotidien
- [ ] Analyse spectrale avancée
- [ ] Détection de duplicata améliorée

### Version 3.0 (Future)
- [ ] Dashboard Vue.js interactif
- [ ] Filtres personnalisés (genre, BPM, key)
- [ ] Playlist Spotify auto-générée
- [ ] Mobile notifications (Push)
- [ ] Machine learning pour recommendations

---

## 🤝 Contribution

Ce projet est personnel mais les suggestions sont bienvenues !

### Comment contribuer

1. Fork le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

---

## 📄 Licence

Projet personnel - Tous droits réservés.

---

## 🙏 Remerciements

- **N8n** - Plateforme d'automation workflow
- **Discogs** - API musicale et base de données vinyle
- **Bandcamp** - Plateforme de découverte musicale
- **Resident Advisor** - Guide des événements électroniques
- **GetSongKey** - API de détection de tonalité

---

## 📞 Support

Pour toute question :
1. Consultez la [documentation](./.claude/plans/quirky-questing-zephyr.md)
2. Vérifiez les [issues GitHub](si applicable)
3. Contactez le mainteneur

---

**Made with ❤️ and Claude Code**

*Dernière mise à jour : 2026-02-02*
