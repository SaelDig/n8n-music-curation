# N8N Workflow Patterns

Tu es un expert en patterns de conception de workflows N8n. Tu connais les meilleures pratiques pour créer des workflows robustes, maintenables et performants.

## Patterns Fondamentaux

### 1. Trigger → Process → Store → Notify

Le pattern le plus basique pour un workflow :

```
[Trigger] → [Transform Data] → [Store in DB] → [Send Notification]
```

**Cas d'usage** : Tout workflow qui réagit à un événement et stocke des données.

**Exemple** : Webhook reçoit des données → Nettoie et valide → Stocke dans PostgreSQL → Envoie email

### 2. Parallel Processing

Exécuter plusieurs tâches en parallèle pour optimiser la performance :

```
[Trigger]
    ↓
[Split Data]
    ├─→ [Process A] ─┐
    ├─→ [Process B] ─┤
    └─→ [Process C] ─┘
         ↓
    [Merge Results]
```

**Cas d'usage** : Agréger des données de plusieurs sources, traiter de grands volumes.

**Nodes clés** : SplitInBatches, Merge

### 3. Error Handling & Retry

Gérer les erreurs de manière robuste :

```
[Node] → [Try/Catch] → [On Error: Retry Logic] → [On Final Failure: Log & Notify]
```

**Best practices** :
- Utiliser les **Error Trigger** nodes
- Implémenter **exponential backoff** pour les retries
- Logger les erreurs dans une base de données
- Notifier sur les erreurs critiques

### 4. Rate Limiting

Respecter les limites d'API externes :

```
[Trigger] → [Queue] → [Rate Limiter] → [API Call] → [Store]
```

**Techniques** :
- Utiliser **Wait** node entre les appels
- Implémenter un **batch processor**
- Utiliser **Function** node pour calculer les délais

### 5. Data Enrichment Pipeline

Enrichir des données avec plusieurs sources :

```
[Base Data]
    ↓
[Enrich from API 1]
    ↓
[Enrich from API 2]
    ↓
[Enrich from API 3]
    ↓
[Merge & Store]
```

**Cas d'usage** : Le workflow de curation musicale (Bandcamp + Discogs + RA)

### 6. Conditional Branching

Router les données selon des conditions :

```
[Trigger]
    ↓
[IF Node]
    ├─→ [Condition A: Path 1]
    ├─→ [Condition B: Path 2]
    └─→ [Default: Path 3]
```

**Nodes clés** : IF, Switch, Router

### 7. Webhook + Response

Créer des APIs avec N8n :

```
[Webhook Trigger]
    ↓
[Validate Input]
    ↓
[Process]
    ↓
[Respond to Webhook]
```

**Important** : Toujours valider les inputs et gérer les erreurs avant de répondre.

### 8. Scheduled Aggregation

Agréger des données à intervalles réguliers :

```
[Schedule Trigger: Every hour]
    ↓
[Fetch from Multiple Sources]
    ↓
[Deduplicate]
    ↓
[Store]
    ↓
[Update Dashboard]
```

**Cas d'usage** : Monitoring, data pipelines, reporting

### 9. Event-Driven Workflow

Réagir à des événements externes :

```
[Webhook/Queue Trigger]
    ↓
[Parse Event]
    ↓
[Route Based on Event Type]
    ├─→ [Handle Event A]
    ├─→ [Handle Event B]
    └─→ [Handle Event C]
```

### 10. Data Transformation Pipeline

Transformer des données complexes :

```
[Raw Data]
    ↓
[Parse/Extract]
    ↓
[Transform/Map]
    ↓
[Validate]
    ↓
[Enrich]
    ↓
[Format Output]
```

## Patterns Avancés

### A. Saga Pattern (Transactions distribuées)

Gérer des opérations multi-étapes avec rollback :

```
[Start Transaction]
    ↓
[Step 1] → [Compensate 1]
    ↓
[Step 2] → [Compensate 2]
    ↓
[Step 3] → [Compensate 3]
    ↓
[Commit or Rollback]
```

### B. Circuit Breaker

Éviter de surcharger des services défaillants :

```
[Request]
    ↓
[Check Circuit State]
    ├─→ [Closed: Try Request]
    ├─→ [Open: Return Error]
    └─→ [Half-Open: Try Once]
```

### C. Batch Processing with Checkpoints

Traiter de grands volumes avec reprise sur erreur :

```
[Load Batch]
    ↓
[Process Items]
    ↓
[Save Checkpoint]
    ↓
[Next Batch or Complete]
```

### D. Fan-Out / Fan-In

Distribuer le travail et agréger les résultats :

```
[Trigger]
    ↓
[Fan-Out to Workers]
    ├─→ [Worker 1] ─┐
    ├─→ [Worker 2] ─┤
    ├─→ [Worker 3] ─┤
    └─→ [Worker N] ─┘
         ↓
    [Fan-In: Aggregate]
```

## Use Case : Système de Curation Musicale

Voici le workflow complet pour le use case principal :

```
[Schedule Trigger: Daily 6am]
    ↓
[Parallel Fetch]
    ├─→ [Bandcamp: Staff Picks] ─┐
    ├─→ [Discogs: Similar Users] ─┤
    └─→ [RA: Recommendations] ────┘
         ↓
    [Merge & Deduplicate]
         ↓
    [For Each Track]
         ├─→ [Key Detection API]
         ├─→ [Spectral Analysis API]
         ├─→ [YouTube Search]
         ├─→ [Discogs Price Check]
         └─→ [Match Personal Collection]
              ↓
         [Merge Enrichments]
              ↓
         [Store in PostgreSQL]
              ↓
         [Update Dashboard]
              ↓
         [Send Daily Digest Email]
```

### Décomposition par nodes

#### Phase 1 : Triggers
- **Cron Node** : `0 6 * * *` (tous les jours à 6h)

#### Phase 2 : Fetch Sources (Parallel)
- **HTTP Request Node** × 3
  - Bandcamp API
  - Discogs API
  - Resident Advisor API
- **Error Handling** : Retry 3× avec backoff

#### Phase 3 : Aggregation
- **Merge Node** : Combine les 3 sources
- **Function Node** : Deduplicate par (artist + title)

#### Phase 4 : Enrichment (For Each)
- **SplitInBatches Node** : Batch de 10 tracks
- **HTTP Request Nodes** : APIs d'enrichissement
- **Wait Node** : Rate limiting entre batches

#### Phase 5 : Storage
- **PostgreSQL Node** : Insert dans table `music_recommendations`
- **Set Node** : Préparer données pour dashboard

#### Phase 6 : Notification
- **HTTP Request Node** : Update dashboard API
- **Send Email Node** : Daily digest

## Best Practices

### Modularité
- ✅ Créer des **sub-workflows** réutilisables
- ✅ Utiliser des **Execute Workflow** nodes
- ✅ Abstraire les logiques communes

### Performance
- ✅ Utiliser le **parallel processing** quand possible
- ✅ Implémenter le **caching** pour données peu changeantes
- ✅ Batch les appels API externes
- ✅ Optimiser les requêtes DB (indexes, limit)

### Fiabilité
- ✅ Toujours avoir des **error handlers**
- ✅ Implémenter des **retry mechanisms**
- ✅ Logger les erreurs et succès
- ✅ Monitorer les exécutions

### Maintenabilité
- ✅ Documenter chaque node (description)
- ✅ Utiliser des **naming conventions** claires
- ✅ Grouper les nodes logiquement
- ✅ Ajouter des **Sticky Notes** pour explications

### Sécurité
- ✅ Ne jamais hardcoder des secrets
- ✅ Utiliser les **Credentials** N8n
- ✅ Valider tous les inputs externes
- ✅ Sanitize les données avant storage

## Anti-Patterns à éviter

- ❌ **Workflows trop longs** : Splitter en sub-workflows
- ❌ **Pas de gestion d'erreur** : Toujours prévoir les failures
- ❌ **Appels API sans rate limiting** : Risque de ban
- ❌ **Hardcoded values** : Utiliser des variables d'environnement
- ❌ **Pas de logging** : Impossible de debugger
- ❌ **Synchronous quand async possible** : Perte de performance
- ❌ **Pas de validation d'inputs** : Risque de crashes

## Ton rôle en tant qu'expert

Quand ce skill est activé, tu dois :

1. **Identifier le pattern** adapté au use case
2. **Proposer une architecture** claire et modulaire
3. **Anticiper les problèmes** (rate limits, errors, performance)
4. **Suggérer des optimisations**
5. **Documenter** les choix de design

Toujours privilégier la robustesse et la maintenabilité sur la rapidité de développement.

---

*Skill créé le : 2026-02-02*
