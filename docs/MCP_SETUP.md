# Configuration MCP N8N

## Endpoint MCP

Ton instance N8n Cloud expose un serveur MCP via HTTP à l'adresse :
```
https://justsaad.app.n8n.cloud/mcp-server/http
```

## Configuration

### 1. Variables d'environnement requises

Dans ton fichier `.env` :

```bash
N8N_INSTANCE_URL=https://justsaad.app.n8n.cloud
N8N_MCP_ENDPOINT=https://justsaad.app.n8n.cloud/mcp-server/http
N8N_API_KEY=your-api-key-here
```

### 2. Authentification

Le serveur MCP nécessite probablement une authentification. Options possibles :
- **API Key** dans les headers HTTP
- **Bearer Token** pour OAuth
- **Session Cookie** si déjà connecté

### 3. Capacités du serveur MCP

Le serveur MCP N8n devrait permettre :
- ✅ Créer des workflows
- ✅ Lire des workflows existants
- ✅ Exécuter des workflows
- ✅ Obtenir les résultats d'exécution
- ✅ Gérer les credentials

## Test de connexion

Pour tester la connexion au serveur MCP, tu peux utiliser :

```bash
curl -X GET https://justsaad.app.n8n.cloud/mcp-server/http \
  -H "Authorization: Bearer YOUR_API_KEY"
```

## Configuration dans Claude Desktop

Si tu utilises Claude Desktop, ajoute cette configuration dans `~/Library/Application Support/Claude/claude_desktop_config.json` :

```json
{
  "mcpServers": {
    "n8n": {
      "type": "http",
      "url": "https://justsaad.app.n8n.cloud/mcp-server/http",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

## Prochaines étapes

1. Obtenir l'API Key depuis ton instance N8n
2. Configurer le fichier `.env` avec tes credentials
3. Tester la connexion MCP
4. Créer le premier workflow de test

## Ressources

- [Documentation N8n API](https://docs.n8n.io/api/)
- [Documentation MCP](https://modelcontextprotocol.io/)
