# PostgreSQL Setup Guide - Music Curation Workflow

## Quick Start

### 1. Install PostgreSQL (if not already installed)

**macOS (using Homebrew):**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download from https://www.postgresql.org/download/windows/

### 2. Create Database and User

Connect to PostgreSQL:
```bash
psql postgres
```

Create database and user:
```sql
-- Create database
CREATE DATABASE n8n_workflows;

-- Create user (replace with your desired password)
CREATE USER n8n_user WITH ENCRYPTED PASSWORD 'your_secure_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE n8n_workflows TO n8n_user;

-- Connect to the new database
\c n8n_workflows

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO n8n_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO n8n_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO n8n_user;

-- Exit
\q
```

### 3. Update .env File

Update your [.env](../.env) file with the real credentials:

```bash
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=n8n_workflows
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=your_secure_password_here
```

### 4. Run Schema Migration

Execute the schema SQL file:

```bash
psql -U n8n_user -d n8n_workflows -f db/schema_v1.sql
```

Or from psql:
```bash
psql -U n8n_user -d n8n_workflows
```

Then:
```sql
\i db/schema_v1.sql
```

### 5. Verify Installation

Run these verification queries:

```sql
-- Check schema version
SELECT * FROM schema_versions;

-- List all tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- List all indexes
SELECT indexname FROM pg_indexes WHERE schemaname = 'public';

-- List all views
SELECT viewname FROM pg_views WHERE schemaname = 'public';
```

Expected output:
```
Tables:
- schema_versions
- music_recommendations
- personal_collection
- workflow_executions
- workflow_errors

Views:
- top_recommendations
- recent_daily_digest
- workflow_execution_summary
```

## Database Schema Overview

### Tables

#### 1. `music_recommendations`
Stores all discovered music tracks with enriched metadata.

**Key columns:**
- `artist`, `title` - Track identification
- `sources` (JSONB) - Array of sources that recommended this track
- `discovery_score` - Number of sources (higher = more important)
- `musical_key`, `camelot_key`, `bpm` - Musical properties
- `youtube_url`, `avg_vinyl_price` - Enrichments
- `mix_suggestions` (JSONB) - Tracks from personal collection to mix with

#### 2. `personal_collection`
Your personal music library (imported from Discogs).

**Key columns:**
- `artist`, `title` - Track identification
- `musical_key`, `camelot_key`, `bpm` - For harmonic mixing
- `discogs_release_id` - Link to Discogs
- `format` - vinyl, digital, cd, etc.

#### 3. `workflow_executions`
Logs every workflow run for monitoring.

**Key columns:**
- `workflow_id`, `execution_id` - Identification
- `status` - success, partial_failure, error
- `tracks_fetched`, `tracks_enriched`, `tracks_stored` - Metrics
- `duration_seconds` - Performance tracking

#### 4. `workflow_errors`
Detailed error logging for debugging.

**Key columns:**
- `error_source` - Which component failed (bandcamp_scraper, discogs_api, etc.)
- `error_message`, `error_data` - Full error details

### Views

#### `top_recommendations`
Top 50 recommendations sorted by discovery score and recency.

```sql
SELECT * FROM top_recommendations LIMIT 10;
```

#### `recent_daily_digest`
Summary statistics by day for the last 7 days.

```sql
SELECT * FROM recent_daily_digest;
```

#### `workflow_execution_summary`
Aggregated execution metrics by day.

```sql
SELECT * FROM workflow_execution_summary;
```

## Useful Queries

### Check today's recommendations

```sql
SELECT artist, title, discovery_score, sources, musical_key, bpm
FROM music_recommendations
WHERE fetched_at >= CURRENT_DATE
ORDER BY discovery_score DESC;
```

### Get multi-source recommendations (high priority)

```sql
SELECT artist, title, discovery_score, sources, youtube_url
FROM music_recommendations
WHERE discovery_score > 1
ORDER BY discovery_score DESC, fetched_at DESC
LIMIT 20;
```

### Check enrichment quality

```sql
SELECT
    COUNT(*) as total,
    COUNT(musical_key) as with_key,
    COUNT(bpm) as with_bpm,
    COUNT(youtube_url) as with_youtube,
    COUNT(avg_vinyl_price) as with_price,
    ROUND(COUNT(musical_key)::numeric / COUNT(*)::numeric * 100, 1) as enrichment_rate
FROM music_recommendations
WHERE fetched_at >= CURRENT_DATE;
```

### Find tracks compatible with a specific key

```sql
-- Example: Find tracks in C or compatible keys
SELECT artist, title, musical_key, camelot_key, bpm
FROM music_recommendations
WHERE camelot_key IN ('8A', '7A', '9A', '8B')  -- Compatible with C (8A)
ORDER BY discovery_score DESC
LIMIT 10;
```

### View recent errors

```sql
SELECT error_source, error_message, created_at
FROM workflow_errors
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY created_at DESC;
```

## Backup & Maintenance

### Backup database

```bash
# Full backup
pg_dump -U n8n_user -d n8n_workflows > backup_$(date +%Y%m%d).sql

# Only recommendations table
pg_dump -U n8n_user -d n8n_workflows -t music_recommendations > recommendations_backup.sql
```

### Restore from backup

```bash
psql -U n8n_user -d n8n_workflows < backup_20260202.sql
```

### Vacuum and analyze (for performance)

```sql
VACUUM ANALYZE music_recommendations;
VACUUM ANALYZE personal_collection;
```

## Troubleshooting

### Connection refused

Check if PostgreSQL is running:
```bash
# macOS
brew services list

# Linux
sudo systemctl status postgresql
```

### Permission denied

Grant all necessary privileges:
```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO n8n_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO n8n_user;
```

### N8n can't connect

1. Check `.env` credentials are correct
2. Verify PostgreSQL accepts connections:
```bash
psql -U n8n_user -d n8n_workflows -h localhost
```

3. Check `pg_hba.conf` allows local connections (usually at `/usr/local/var/postgresql@15/pg_hba.conf`)

## Next Steps

Once PostgreSQL is set up:

1. ✅ Import your Discogs collection (via N8n workflow)
2. ✅ Create the main music curation workflow
3. ✅ Test workflow execution
4. ✅ Set up daily scheduling

See main [README.md](../README.md) for workflow implementation.
