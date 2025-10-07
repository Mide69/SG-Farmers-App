-- SG Farmers App Database Schema

-- Create database extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Farmers table
CREATE TABLE IF NOT EXISTS farmers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    farm_location TEXT,
    farm_size VARCHAR(50),
    crop_types TEXT[],
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Grant applications table
CREATE TABLE IF NOT EXISTS grant_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    grant_type VARCHAR(100) NOT NULL,
    amount_requested DECIMAL(12,2),
    purpose TEXT,
    documents JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    review_date TIMESTAMP,
    reviewer_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chat history table
CREATE TABLE IF NOT EXISTS chat_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    user_message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    application_id UUID REFERENCES grant_applications(id) ON DELETE CASCADE,
    document_name VARCHAR(255) NOT NULL,
    document_type VARCHAR(100),
    file_path TEXT,
    file_size INTEGER,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    read_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin users table
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'admin',
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_farmers_email ON farmers(email);
CREATE INDEX IF NOT EXISTS idx_farmers_location ON farmers USING gin(farm_location gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_farmers_crop_types ON farmers USING gin(crop_types);
CREATE INDEX IF NOT EXISTS idx_grant_applications_farmer_id ON grant_applications(farmer_id);
CREATE INDEX IF NOT EXISTS idx_grant_applications_status ON grant_applications(status);
CREATE INDEX IF NOT EXISTS idx_grant_applications_type ON grant_applications(grant_type);
CREATE INDEX IF NOT EXISTS idx_chat_history_farmer_id ON chat_history(farmer_id);
CREATE INDEX IF NOT EXISTS idx_chat_history_created_at ON chat_history(created_at);
CREATE INDEX IF NOT EXISTS idx_documents_farmer_id ON documents(farmer_id);
CREATE INDEX IF NOT EXISTS idx_documents_application_id ON documents(application_id);
CREATE INDEX IF NOT EXISTS idx_notifications_farmer_id ON notifications(farmer_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read_status ON notifications(read_status);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_farmers_updated_at BEFORE UPDATE ON farmers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grant_applications_updated_at BEFORE UPDATE ON grant_applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO farmers (name, email, phone, farm_location, farm_size, crop_types) VALUES
('John Tan', 'john.tan@email.com', '+65 9123 4567', 'Kranji', 'Small (< 1 hectare)', ARRAY['Rice', 'Vegetables']),
('Mary Lim', 'mary.lim@email.com', '+65 9234 5678', 'Lim Chu Kang', 'Medium (1-5 hectares)', ARRAY['Fruits', 'Herbs']),
('David Wong', 'david.wong@email.com', '+65 9345 6789', 'Sungei Tengah', 'Large (> 5 hectares)', ARRAY['Leafy Greens', 'Mushrooms'])
ON CONFLICT (email) DO NOTHING;