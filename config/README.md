# Configuration

## Setup

1. Copie le fichier `.env.example` vers `.env` à la racine du projet :
   ```bash
   cp .env.example .env
   ```

2. Remplis les variables d'environnement avec tes credentials N8n Cloud :
   - `N8N_INSTANCE_URL` : URL de ton instance N8n Cloud
   - `N8N_API_KEY` : Clé API générée depuis ton instance N8n

## Sécurité

- Le fichier `.env` est ignoré par git pour ne pas exposer tes credentials
- Ne commite JAMAIS tes credentials dans le repository
- Utilise des variables d'environnement différentes pour dev/staging/prod

## Configuration MCP N8N

Le serveur MCP N8N utilisera ces variables pour se connecter à ton instance N8n Cloud.

### Variables requises :
- `N8N_INSTANCE_URL` : URL complète de l'instance
- `N8N_API_KEY` : Clé API pour authentification

## PostgreSQL

Configuration de la base de données pour stocker les résultats des workflows et les métadonnées enrichies.

Cette configuration sera nécessaire pour le use case de curation musicale.
