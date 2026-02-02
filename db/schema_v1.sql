-- ============================================================
-- N8n Music Curation - Database Schema v1
-- ============================================================
-- Description: Complete database schema for the music curation workflow
-- Date: 2026-02-02
-- ============================================================

-- Create schema version tracking
CREATE TABLE IF NOT EXISTS schema_versions (
    version INTEGER PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMP DEFAULT NOW()
);

-- Insert initial version
INSERT INTO schema_versions (version, description)
VALUES (1, 'Initial schema for music curation workflow - 4 tables')
ON CONFLICT (version) DO NOTHING;

-- ============================================================
-- TABLE 1: music_recommendations
-- ============================================================
-- Stores all music recommendations from various sources
-- with enriched metadata and mix suggestions

CREATE TABLE IF NOT EXISTS music_recommendations (
    id SERIAL PRIMARY KEY,

    -- Basic track info
    artist VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,

    -- Source tracking
    sources JSONB NOT NULL,  -- Array of sources: ["bandcamp", "discogs", "resident_advisor"]
    discovery_score INTEGER DEFAULT 1,  -- Number of sources recommending this track

    -- Source-specific URLs
    source_url VARCHAR(500),
    bandcamp_url VARCHAR(500),
    discogs_release_id INTEGER,
    ra_event_id INTEGER,

    -- Musical properties
    musical_key VARCHAR(10),  -- e.g., "C", "D#m", "Bb"
    camelot_key VARCHAR(5),   -- e.g., "8A", "3B" (for harmonic mixing)
    bpm DECIMAL(5,2),         -- Beats per minute
    time_signature INTEGER,   -- e.g., 4 for 4/4
    genre VARCHAR(100),

    -- Enrichment data
    youtube_url VARCHAR(500),
    avg_vinyl_price DECIMAL(8,2),  -- Average vinyl price in EUR
    spectral_features JSONB,  -- {danceability, energy, acousticness, etc.}

    -- Mix suggestions from personal collection
    mix_suggestions JSONB,  -- [{track_id, artist, title, match_score, reason}]

    -- Timestamps
    fetched_at TIMESTAMP NOT NULL,
    enriched_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Constraints
    UNIQUE(artist, title)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_recommendations_artist ON music_recommendations(artist);
CREATE INDEX IF NOT EXISTS idx_recommendations_genre ON music_recommendations(genre);
CREATE INDEX IF NOT EXISTS idx_recommendations_key ON music_recommendations(musical_key);
CREATE INDEX IF NOT EXISTS idx_recommendations_bpm ON music_recommendations(bpm);
CREATE INDEX IF NOT EXISTS idx_recommendations_discovery_score ON music_recommendations(discovery_score DESC);
CREATE INDEX IF NOT EXISTS idx_recommendations_fetched_at ON music_recommendations(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_recommendations_sources ON music_recommendations USING GIN(sources);

-- ============================================================
-- TABLE 2: personal_collection
-- ============================================================
-- Stores the user's personal music collection
-- (imported from Discogs or manual entry)

CREATE TABLE IF NOT EXISTS personal_collection (
    id SERIAL PRIMARY KEY,

    -- Track info
    artist VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,

    -- Musical properties
    musical_key VARCHAR(10),
    camelot_key VARCHAR(5),
    bpm DECIMAL(5,2),
    genre VARCHAR(100),
    energy DECIMAL(3,2),  -- 0.0 to 1.0 (for spectral matching)

    -- Format and source
    format VARCHAR(50),  -- "vinyl", "digital", "cd", etc.
    discogs_release_id INTEGER UNIQUE,

    -- Timestamps
    added_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Constraints
    UNIQUE(artist, title)
);

-- Indexes for matching algorithm
CREATE INDEX IF NOT EXISTS idx_collection_key ON personal_collection(musical_key);
CREATE INDEX IF NOT EXISTS idx_collection_camelot ON personal_collection(camelot_key);
CREATE INDEX IF NOT EXISTS idx_collection_bpm ON personal_collection(bpm);
CREATE INDEX IF NOT EXISTS idx_collection_genre ON personal_collection(genre);

-- ============================================================
-- TABLE 3: workflow_executions
-- ============================================================
-- Tracks each workflow execution for monitoring and analytics

CREATE TABLE IF NOT EXISTS workflow_executions (
    id SERIAL PRIMARY KEY,
    workflow_id VARCHAR(100) NOT NULL,
    execution_id VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL,  -- "success", "partial_failure", "error"

    -- Execution metrics
    tracks_fetched INTEGER DEFAULT 0,
    tracks_enriched INTEGER DEFAULT 0,
    tracks_stored INTEGER DEFAULT 0,
    duration_seconds INTEGER,

    -- Error tracking
    error_message TEXT,

    -- Timestamps
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,

    -- Additional metadata (sources performance, API usage, etc.)
    metadata JSONB
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_executions_workflow ON workflow_executions(workflow_id);
CREATE INDEX IF NOT EXISTS idx_executions_status ON workflow_executions(status);
CREATE INDEX IF NOT EXISTS idx_executions_started ON workflow_executions(started_at DESC);

-- ============================================================
-- TABLE 4: workflow_errors
-- ============================================================
-- Logs all errors encountered during workflow execution

CREATE TABLE IF NOT EXISTS workflow_errors (
    id SERIAL PRIMARY KEY,
    workflow_id VARCHAR(100) NOT NULL,
    execution_id VARCHAR(100),
    error_source VARCHAR(100),  -- "bandcamp_scraper", "discogs_api", "youtube_api", etc.
    error_message TEXT NOT NULL,
    error_data JSONB,  -- Full error details
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_errors_workflow ON workflow_errors(workflow_id);
CREATE INDEX IF NOT EXISTS idx_errors_source ON workflow_errors(error_source);
CREATE INDEX IF NOT EXISTS idx_errors_created ON workflow_errors(created_at DESC);

-- ============================================================
-- VIEWS
-- ============================================================

-- Top recommendations (multi-source, enriched)
CREATE OR REPLACE VIEW top_recommendations AS
SELECT
    id,
    artist,
    title,
    discovery_score,
    musical_key,
    camelot_key,
    bpm,
    genre,
    youtube_url,
    avg_vinyl_price,
    sources,
    (SELECT COUNT(*)
     FROM jsonb_array_elements(COALESCE(mix_suggestions, '[]'::jsonb))) as mix_match_count,
    fetched_at,
    enriched_at
FROM music_recommendations
WHERE enriched_at IS NOT NULL
ORDER BY discovery_score DESC, fetched_at DESC
LIMIT 50;

-- Recent daily digest stats
CREATE OR REPLACE VIEW recent_daily_digest AS
SELECT
    DATE(fetched_at) as digest_date,
    COUNT(*) as total_tracks,
    COUNT(DISTINCT artist) as unique_artists,
    ROUND(AVG(discovery_score), 2) as avg_score,
    COUNT(CASE WHEN enriched_at IS NOT NULL THEN 1 END) as enriched_tracks,
    COUNT(CASE WHEN youtube_url IS NOT NULL THEN 1 END) as tracks_with_youtube,
    STRING_AGG(DISTINCT genre, ', ') as genres
FROM music_recommendations
WHERE fetched_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(fetched_at)
ORDER BY digest_date DESC;

-- Workflow execution summary
CREATE OR REPLACE VIEW workflow_execution_summary AS
SELECT
    DATE(started_at) as execution_date,
    COUNT(*) as total_executions,
    SUM(tracks_fetched) as total_tracks_fetched,
    SUM(tracks_enriched) as total_tracks_enriched,
    SUM(tracks_stored) as total_tracks_stored,
    ROUND(AVG(duration_seconds), 0) as avg_duration_seconds,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_executions,
    COUNT(CASE WHEN status = 'error' THEN 1 END) as failed_executions
FROM workflow_executions
WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(started_at)
ORDER BY execution_date DESC;

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to auto-update updated_at
CREATE TRIGGER update_music_recommendations_updated_at
    BEFORE UPDATE ON music_recommendations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_personal_collection_updated_at
    BEFORE UPDATE ON personal_collection
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- INITIAL DATA (Optional)
-- ============================================================

-- Insert sample personal collection entry (for testing)
-- Uncomment to add sample data:
-- INSERT INTO personal_collection (artist, title, musical_key, camelot_key, bpm, genre, format)
-- VALUES ('Daft Punk', 'Around The World', 'C#m', '9A', 121, 'House', 'vinyl')
-- ON CONFLICT (artist, title) DO NOTHING;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Run these queries to verify the schema was created correctly:

-- SELECT * FROM schema_versions;
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT indexname FROM pg_indexes WHERE schemaname = 'public';
-- SELECT viewname FROM pg_views WHERE schemaname = 'public';

-- ============================================================
-- DONE!
-- ============================================================
