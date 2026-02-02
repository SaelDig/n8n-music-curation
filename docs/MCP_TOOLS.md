# Outils MCP N8N Disponibles

Le serveur MCP N8n expose 3 outils pour interagir avec ton instance N8n Cloud.

## 1. search_workflows

**Description** : Recherche des workflows avec des filtres optionnels. Retourne un aperçu de chaque workflow.

**Paramètres** :
- `limit` (integer, optionnel) : Limite le nombre de résultats (max 200)
- `query` (string, optionnel) : Filtre par nom ou description
- `projectId` (string, optionnel) : Filtre par projet

**Exemple d'utilisation** :
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "search_workflows",
    "arguments": {
      "limit": 10,
      "query": "music"
    }
  }
}
```

**Retour** :
```json
{
  "data": [
    {
      "id": "workflow-id",
      "name": "Music Curation",
      "description": "Aggregates music recommendations",
      "active": true,
      "createdAt": "2026-02-02T10:00:00Z",
      "updatedAt": "2026-02-02T11:00:00Z",
      "triggerCount": 1,
      "nodes": [
        {"name": "Start", "type": "n8n-nodes-base.start"},
        {"name": "HTTP Request", "type": "n8n-nodes-base.httpRequest"}
      ]
    }
  ],
  "count": 1
}
```

---

## 2. get_workflow_details

**Description** : Obtient les détails complets d'un workflow spécifique, incluant les informations sur les triggers.

**Paramètres** :
- `workflowId` (string, requis) : L'ID du workflow à récupérer

**Exemple d'utilisation** :
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "get_workflow_details",
    "arguments": {
      "workflowId": "workflow-id"
    }
  }
}
```

**Retour** :
```json
{
  "workflow": {
    "id": "workflow-id",
    "name": "Music Curation",
    "active": true,
    "isArchived": false,
    "versionId": "version-id",
    "triggerCount": 1,
    "createdAt": "2026-02-02T10:00:00Z",
    "updatedAt": "2026-02-02T11:00:00Z",
    "description": "Aggregates music from multiple sources",
    "settings": {},
    "connections": {},
    "nodes": [...],
    "tags": [],
    "parentFolderId": null,
    "meta": {}
  },
  "triggerInfo": "This workflow is triggered by a webhook. Send a POST request to..."
}
```

**Important** : Toujours utiliser cet outil avant d'exécuter un workflow pour comprendre son schéma d'entrée.

---

## 3. execute_workflow

**Description** : Exécute un workflow par son ID. Vérifie toujours le schéma d'entrée avec `get_workflow_details` avant d'exécuter.

**Paramètres** :
- `workflowId` (string, requis) : L'ID du workflow à exécuter
- `inputs` (object, optionnel) : Données d'entrée selon le type de trigger

### Types d'inputs supportés :

#### a) Chat-based workflows
```json
{
  "type": "chat",
  "chatInput": "Your message here"
}
```

#### b) Form-based workflows
```json
{
  "type": "form",
  "formData": {
    "field1": "value1",
    "field2": "value2"
  }
}
```

#### c) Webhook-based workflows
```json
{
  "type": "webhook",
  "webhookData": {
    "method": "POST",
    "query": {
      "param1": "value1"
    },
    "body": {
      "key": "value"
    },
    "headers": {
      "Content-Type": "application/json",
      "Authorization": "Bearer token"
    }
  }
}
```

**Exemple complet** :
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "execute_workflow",
    "arguments": {
      "workflowId": "workflow-id",
      "inputs": {
        "type": "webhook",
        "webhookData": {
          "method": "POST",
          "body": {
            "artist": "Daft Punk",
            "genre": "Electronic"
          }
        }
      }
    }
  }
}
```

**Retour** :
```json
{
  "success": true,
  "executionId": "execution-id",
  "result": {
    // Données retournées par le workflow
  },
  "error": null
}
```

---

## Workflow de travail recommandé

1. **Rechercher** un workflow : `search_workflows`
2. **Obtenir les détails** : `get_workflow_details` pour comprendre les inputs requis
3. **Exécuter** le workflow : `execute_workflow` avec les bons paramètres

## Notes importantes

- ⚠️ `execute_workflow` est marqué comme **destructive** (peut modifier des données)
- ✅ `search_workflows` et `get_workflow_details` sont **read-only** (lecture seule)
- 🔄 Tous les outils sont **idempotent** (même requête = même résultat)
- 🌐 `execute_workflow` est **open-world** (peut interagir avec des systèmes externes)

## Exemples avec curl

### Rechercher des workflows
```bash
curl -X POST https://justsaad.app.n8n.cloud/mcp-server/http \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "search_workflows",
      "arguments": {"limit": 10}
    }
  }'
```

### Obtenir les détails d'un workflow
```bash
curl -X POST https://justsaad.app.n8n.cloud/mcp-server/http \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "get_workflow_details",
      "arguments": {"workflowId": "WORKFLOW_ID"}
    }
  }'
```

### Exécuter un workflow
```bash
curl -X POST https://justsaad.app.n8n.cloud/mcp-server/http \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "execute_workflow",
      "arguments": {
        "workflowId": "WORKFLOW_ID",
        "inputs": {
          "type": "webhook",
          "webhookData": {
            "method": "POST",
            "body": {"key": "value"}
          }
        }
      }
    }
  }'
```

---

*Documentation mise à jour : 2026-02-02*
