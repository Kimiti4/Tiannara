-- Tiannara MindCache Database Initialization
-- This script runs automatically when the PostgreSQL container starts

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create tables (if they don't exist)

-- Memory Store
CREATE TABLE IF NOT EXISTS memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding VECTOR(768),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for text search
CREATE INDEX IF NOT EXISTS idx_memories_content ON memories USING gin(to_tsvector('english', content));

-- Create index for metadata queries
CREATE INDEX IF NOT EXISTS idx_memories_metadata ON memories USING gin(metadata);

-- Experiences
CREATE TABLE IF NOT EXISTS experiences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255),
    action TEXT NOT NULL,
    context JSONB DEFAULT '{}',
    outcome TEXT,
    confidence FLOAT DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for user queries
CREATE INDEX IF NOT EXISTS idx_experiences_user_id ON experiences(user_id);

-- Goals
CREATE TABLE IF NOT EXISTS goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    priority INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Preferences
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) UNIQUE NOT NULL,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System Logs
CREATE TABLE IF NOT EXISTS system_logs (
    id BIGSERIAL PRIMARY KEY,
    level VARCHAR(10) NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for log queries
CREATE INDEX IF NOT EXISTS idx_system_logs_level ON system_logs(level);
CREATE INDEX IF NOT EXISTS idx_system_logs_created ON system_logs(created_at);

-- Insert sample data (optional - comment out in production)
-- INSERT INTO goals (name, description, status, priority) VALUES
--     ('System Health', 'Monitor system performance and stability', 'active', 1),
--     ('User Satisfaction', 'Improve user experience and satisfaction', 'active', 2);

COMMENT ON TABLE memories IS 'Stores semantic memories with embeddings for retrieval';
COMMENT ON TABLE experiences IS 'Records user interactions and outcomes for learning';
COMMENT ON TABLE goals IS 'Tracks system and user goals';
COMMENT ON TABLE user_preferences IS 'Stores user-specific preferences and settings';
COMMENT ON TABLE system_logs IS 'Application logs for monitoring and debugging';
