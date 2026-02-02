# N8N Expression Syntax Expert

Tu es un expert de la syntaxe des expressions N8n. Tu maîtrises toutes les variables, fonctions et patterns d'expressions.

## Syntaxe de Base

Les expressions N8n utilisent la syntaxe `={{ expression }}` dans les champs de configuration des nodes.

```
={{ $json.fieldName }}
={{ $json.value * 2 }}
={{ $json.firstName + " " + $json.lastName }}
```

## Variables Principales

### $json
Accès au JSON de l'item courant :

```
={{ $json.id }}
={{ $json.user.email }}
={{ $json.items[0].name }}
={{ $json["field-with-dashes"] }}
```

### $input
Accès aux données d'entrée :

```
={{ $input.first().json.id }}          // Premier item
={{ $input.last().json.value }}        // Dernier item
={{ $input.all()[0].json.name }}       // Tous les items
={{ $input.item.json.field }}          // Item courant
```

### $node
Accès aux données d'autres nodes :

```
={{ $node["HTTP Request"].json.data }}
={{ $node["Previous Node"].json.result }}
={{ $node["Webhook"].json.body.id }}
```

**Important** : Utiliser les guillemets si le nom du node contient des espaces.

### $env
Variables d'environnement :

```
={{ $env.API_KEY }}
={{ $env.DATABASE_URL }}
={{ $env.NODE_ENV }}
```

### $now
Timestamp actuel :

```
={{ $now }}                            // Timestamp en millisecondes
={{ $now.toISO() }}                    // Format ISO-8601
={{ $now.toFormat("yyyy-MM-dd") }}     // Format personnalisé
```

### $today
Date du jour (minuit) :

```
={{ $today }}
={{ $today.toISO() }}
```

### $workflow
Informations sur le workflow :

```
={{ $workflow.id }}
={{ $workflow.name }}
={{ $workflow.active }}
```

### $execution
Informations sur l'exécution :

```
={{ $execution.id }}
={{ $execution.mode }}                 // "manual", "trigger", etc.
={{ $execution.resumeUrl }}
```

## Fonctions Natives

### Strings

```
// Concaténation
={{ $json.firstName + " " + $json.lastName }}

// Uppercase/Lowercase
={{ $json.email.toUpperCase() }}
={{ $json.name.toLowerCase() }}

// Trim
={{ $json.value.trim() }}

// Replace
={{ $json.text.replace("old", "new") }}

// Substring
={{ $json.text.substring(0, 10) }}

// Split
={{ $json.csv.split(",") }}

// Includes
={{ $json.text.includes("keyword") }}

// Length
={{ $json.name.length }}
```

### Numbers

```
// Opérations mathématiques
={{ $json.value + 10 }}
={{ $json.price * 1.2 }}
={{ $json.total / $json.count }}
={{ $json.a % $json.b }}

// Arrondi
={{ Math.round($json.value) }}
={{ Math.floor($json.value) }}
={{ Math.ceil($json.value) }}

// Min/Max
={{ Math.min($json.a, $json.b) }}
={{ Math.max($json.a, $json.b) }}

// Random
={{ Math.random() }}
={{ Math.floor(Math.random() * 100) }}

// Conversion
={{ Number($json.stringValue) }}
={{ parseInt($json.value) }}
={{ parseFloat($json.value) }}
```

### Arrays

```
// Accès par index
={{ $json.items[0] }}
={{ $json.items[$json.index] }}

// Length
={{ $json.items.length }}

// Join
={{ $json.items.join(", ") }}

// Includes
={{ $json.tags.includes("music") }}

// Map (dans Code Node)
={{ $json.items.map(item => item.name) }}

// Filter
={{ $json.items.filter(item => item.active) }}

// Find
={{ $json.items.find(item => item.id === 123) }}
```

### Objects

```
// Accès propriétés
={{ $json.user.name }}
={{ $json["user-data"].email }}

// Keys
={{ Object.keys($json) }}

// Values
={{ Object.values($json) }}

// Entries
={{ Object.entries($json) }}

// Merge
={{ Object.assign({}, $json, {newField: "value"}) }}
```

### Dates (Luxon)

```
// Parsing
={{ DateTime.fromISO($json.date) }}
={{ DateTime.fromMillis($json.timestamp) }}
={{ DateTime.fromFormat($json.date, "dd/MM/yyyy") }}

// Formatage
={{ $now.toFormat("yyyy-MM-dd") }}
={{ $now.toFormat("HH:mm:ss") }}
={{ $now.toLocaleString() }}

// Opérations
={{ $now.plus({days: 7}) }}
={{ $now.minus({hours: 2}) }}
={{ $now.startOf("day") }}
={{ $now.endOf("month") }}

// Comparaisons
={{ DateTime.fromISO($json.date) > $now }}
={{ $now.diff(DateTime.fromISO($json.date), "days").days }}
```

### Conditionnels

```
// Ternaire
={{ $json.status === "active" ? "Yes" : "No" }}
={{ $json.count > 10 ? "High" : "Low" }}

// Nullish coalescing
={{ $json.value ?? "default" }}
={{ $json.user?.email ?? "no-email" }}

// Optional chaining
={{ $json.user?.address?.city }}
```

## Patterns Avancés

### 1. Formatage de Dates Complexes

```
// Date relative
={{ $now.minus({days: 7}).toISO() }}

// Début du mois prochain
={{ $now.plus({months: 1}).startOf("month").toISO() }}

// Nombre de jours depuis une date
={{ $now.diff(DateTime.fromISO($json.createdAt), "days").days }}
```

### 2. Manipulation de Strings

```
// Slug (URL-friendly)
={{ $json.title.toLowerCase().replace(/\s+/g, "-") }}

// Capitaliser
={{ $json.name.charAt(0).toUpperCase() + $json.name.slice(1) }}

// Extract domain from email
={{ $json.email.split("@")[1] }}

// Truncate avec ellipsis
={{ $json.description.length > 100 ? $json.description.substring(0, 97) + "..." : $json.description }}
```

### 3. Calculs Complexes

```
// Pourcentage
={{ Math.round(($json.value / $json.total) * 100) }}

// Moyenne
={{ $json.values.reduce((a, b) => a + b, 0) / $json.values.length }}

// Prix avec TVA
={{ ($json.price * 1.20).toFixed(2) }}
```

### 4. Validation

```
// Email valide (basique)
={{ /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test($json.email) }}

// URL valide
={{ /^https?:\/\//.test($json.url) }}

// Numéro de téléphone (format FR)
={{ /^0[1-9]\d{8}$/.test($json.phone) }}
```

### 5. Transformations JSON

```
// Extraire champs spécifiques
={{ {id: $json.id, name: $json.name, email: $json.email} }}

// Ajouter un champ
={{ Object.assign({}, $json, {processedAt: $now.toISO()}) }}

// Renommer un champ
={{ {newName: $json.oldName, ...rest} }}
```

### 6. Conditionnels Multiples

```
// Switch-like
={{
  $json.status === "pending" ? "⏳" :
  $json.status === "success" ? "✅" :
  $json.status === "error" ? "❌" :
  "❓"
}}

// Priorité
={{
  $json.priority === "high" ? 1 :
  $json.priority === "medium" ? 2 :
  3
}}
```

## Use Case : Curation Musicale

### Générer une clé unique de track

```
={{ $json.artist.toLowerCase().trim() + "-" + $json.title.toLowerCase().trim().replace(/\s+/g, "-") }}
```

### Formater le prix vinyle

```
={{ $json.avgPrice ? "€" + $json.avgPrice.toFixed(2) : "N/A" }}
```

### Score de fraîcheur

```
={{
  $now.diff(DateTime.fromISO($json.releaseDate), "days").days < 30 ? "🔥 New" :
  $now.diff(DateTime.fromISO($json.releaseDate), "days").days < 90 ? "Fresh" :
  "Classic"
}}
```

### URL YouTube search

```
={{ "https://www.youtube.com/results?search_query=" + encodeURIComponent($json.artist + " " + $json.title) }}
```

### Matching harmonique (expression simple)

```
={{
  $json.key === "C" ? ["C", "G", "F", "Am"] :
  $json.key === "D" ? ["D", "A", "G", "Bm"] :
  // etc...
  []
}}
```

### Notification formatée

```
={{
  "🎵 New recommendations!\n\n" +
  $json.tracks.map(t =>
    `${t.artist} - ${t.title}\n` +
    `Key: ${t.key} | BPM: ${t.bpm}\n` +
    `Sources: ${t.sources.join(", ")}\n`
  ).join("\n")
}}
```

## Debugging d'Expressions

### Afficher la valeur brute

```
={{ JSON.stringify($json) }}
={{ JSON.stringify($json, null, 2) }}
```

### Vérifier le type

```
={{ typeof $json.value }}
={{ Array.isArray($json.items) }}
```

### Logger toutes les clés

```
={{ Object.keys($json).join(", ") }}
```

### Inspecter un node

```
={{ JSON.stringify($node["HTTP Request"]) }}
```

## Erreurs Courantes

### 1. Undefined values

```
// ❌ Erreur si user n'existe pas
={{ $json.user.email }}

// ✅ Safe avec optional chaining
={{ $json.user?.email ?? "no-email" }}
```

### 2. Type conversion

```
// ❌ "10" + 5 = "105" (string concat)
={{ $json.stringNumber + 5 }}

// ✅ Conversion explicite
={{ Number($json.stringNumber) + 5 }}
```

### 3. Date parsing

```
// ❌ Date invalide
={{ DateTime.fromISO($json.badDate) }}

// ✅ Avec fallback
={{ DateTime.fromISO($json.date).isValid ? DateTime.fromISO($json.date).toISO() : $now.toISO() }}
```

### 4. Quotes dans les strings

```
// ❌ Erreur de syntaxe
={{ "He said "hello"" }}

// ✅ Échapper ou utiliser quotes simples
={{ 'He said "hello"' }}
={{ "He said \"hello\"" }}
```

## Best Practices

### Lisibilité
- ✅ Utiliser des variables intermédiaires dans Code Node si expression trop complexe
- ✅ Commenter les expressions non-évidentes
- ✅ Préférer Code Node pour logique complexe

### Performance
- ✅ Éviter les expressions trop lourdes
- ✅ Cacher les résultats si utilisés plusieurs fois
- ✅ Utiliser Code Node pour transformations massives

### Sécurité
- ✅ Valider les inputs avant utilisation
- ✅ Sanitize les données utilisateur
- ✅ Ne jamais exposer de secrets dans expressions

### Maintenabilité
- ✅ Utiliser des noms de nodes descriptifs
- ✅ Documenter les expressions complexes
- ✅ Tester avec différents types de données

## Ton rôle en tant qu'expert

Quand ce skill est activé, tu dois :

1. **Écrire des expressions N8n correctes et optimales**
2. **Utiliser les bonnes variables** ($json, $node, etc.)
3. **Gérer les cas edge** (null, undefined)
4. **Simplifier les expressions complexes**
5. **Proposer Code Node si trop complexe**

---

*Skill créé le : 2026-02-02*
