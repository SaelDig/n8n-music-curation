# N8N Builder - Documentation Projet

## Vue d'ensemble

Ce projet est un builder de workflows N8n utilisant Vue.js. L'objectif est de créer des workflows N8n sophistiqués et de haute qualité pour automatiser des processus complexes, en particulier dans le domaine de la curation musicale collaborative.

## Architecture & Outils

### MCP N8N (Serveur MCP)
Serveur opérationnel qui fournit l'interface avec N8n. Capacités :
- **Création** de workflows N8n
- **Lecture** de workflows existants
- **Exécution** de workflows

Ce serveur est le lien opérationnel principal avec l'instance N8n.

### Skills N8N
Skills personnalisés à créer pour faciliter le développement de workflows. Ces skills fourniront des abstractions de haut niveau pour :
- Templates de workflows courants
- Patterns de conception N8n
- Intégrations pré-configurées
- Helpers pour tâches répétitives

### Stack Technique
- **Frontend** : Vue.js
- **Backend Workflow** : N8n
- **Base de données** : PostgreSQL (pour stockage et analyse)
- **Outils d'intégration** : MCP N8N

## Use Case Principal : Système de Curation Musicale Collaborative

### Description
Workflow ambitieux qui agrège des sources musicales multiples pour créer un système de recommandation personnalisé et enrichi.

### Sources de Données
1. **Bandcamp** : Staff picks
2. **Discogs** : Charts de collectionneurs similaires (identifiés par analyse de wantlists communes)
3. **Resident Advisor** : Recommendations basées sur l'historique d'écoute

### Enrichissement des Données
Chaque recommandation musicale inclut :
- **Key detection** : Détection de la tonalité musicale
- **Analyse spectrale** : Analyse des caractéristiques audio
- **Liens YouTube** : Samples vidéo pour prévisualisation
- **Prix vinyle moyen** : Information de marché
- **Suggestions de mix** : Tracks de la collection personnelle qui matcheraient bien

### Stockage & Analyse
- Données stockées dans **PostgreSQL**
- Permet analyse ultérieure avec outils existants
- Dashboard personnalisé pour visualisation

### Architecture du Workflow
```
[Sources Multiples]
    ↓
[Agrégation & Déduplication]
    ↓
[Enrichissement Métadonnées]
    ↓
[Analyse & Matching]
    ↓
[Stockage PostgreSQL]
    ↓
[Dashboard Vue.js]
```

## Guidelines pour Création de Workflows

### Principes de Qualité
1. **Modularité** : Créer des workflows réutilisables et composables
2. **Gestion d'erreurs** : Implémenter une gestion robuste des erreurs et retry logic
3. **Performance** : Optimiser les appels API et le traitement de données
4. **Logging** : Tracer les exécutions pour debugging
5. **Scalabilité** : Concevoir pour supporter des volumes croissants

### Patterns Recommandés
- **Trigger → Process → Store → Notify**
- **Parallel processing** pour sources multiples
- **Rate limiting** pour APIs externes
- **Caching** pour données peu changeantes
- **Batch processing** pour grandes quantités de données

### Intégrations Clés
- **APIs REST** : Bandcamp, Discogs, Resident Advisor
- **Traitement Audio** : Key detection, analyse spectrale
- **Base de données** : PostgreSQL queries & storage
- **Web scraping** : Pour données non disponibles via API
- **Webhooks** : Pour notifications et triggers

## Rôle de Claude

En tant qu'assistant, je dois :
1. **Créer les Skills N8N** pour faciliter le développement
2. **Concevoir des workflows** répondant aux use cases
3. **Utiliser le MCP N8N** pour opérer sur l'instance N8n
4. **Développer l'interface Vue.js** pour le builder et dashboards
5. **Optimiser et debugger** les workflows existants
6. **Proposer des améliorations** architecturales
7. **Documenter** les patterns et solutions

## Structure du Projet

```
N8N-builder/
├── claude.md              # Cette documentation
├── skills/                # Skills N8N personnalisés (à créer)
├── workflows/             # Templates et workflows N8n
├── src/                   # Code source Vue.js
│   ├── components/        # Composants Vue
│   ├── views/             # Pages/vues
│   ├── services/          # Services API
│   └── utils/             # Utilitaires
├── docs/                  # Documentation additionnelle
└── tests/                 # Tests
```

## Installation & Configuration

### Prérequis
- Node.js
- Vue.js
- PostgreSQL
- Instance N8n (à configurer)

### Étapes d'installation
(À compléter lors de la mise en place)

## Roadmap

### Phase 1 : Setup
- [ ] Configurer instance N8n
- [ ] Créer skills N8N de base
- [ ] Setup projet Vue.js
- [ ] Configurer PostgreSQL

### Phase 2 : Use Case Curation Musicale
- [ ] Intégrations APIs (Bandcamp, Discogs, RA)
- [ ] Workflow d'agrégation
- [ ] Enrichissement métadonnées
- [ ] Analyse et matching
- [ ] Dashboard Vue.js

### Phase 3 : Généralisation
- [ ] Abstraire les patterns
- [ ] Créer templates réutilisables
- [ ] Documentation complète
- [ ] Tests et optimisations

## Notes Importantes

- Le builder doit être **flexible** pour couvrir divers use cases au-delà de la curation musicale
- Privilégier la **qualité** sur la rapidité de développement
- Maintenir une **documentation vivante** au fur et à mesure
- Tester les workflows dans des conditions réelles

## Ressources

- [Documentation N8n](https://docs.n8n.io/)
- [Vue.js Documentation](https://vuejs.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- APIs à documenter : Bandcamp, Discogs, Resident Advisor

---

*Ce document évolue avec le projet. Dernière mise à jour : 2026-02-02*
