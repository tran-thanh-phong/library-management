-- ============================================================================
-- Library Management System - Database Schema
-- PostgreSQL / Supabase Migration Script
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

-- User roles: Reader (độc giả), Librarian (nhân viên), Admin (quản lý viên)
CREATE TYPE user_role AS ENUM ('reader', 'librarian', 'admin');

-- User status: Pending (chờ xác nhận), Active (kích hoạt), Disabled (vô hiệu hóa)
CREATE TYPE user_status AS ENUM ('pending', 'active', 'disabled');

-- Borrow request status: Pending, Approved, Rejected, Borrowed, Returned, Overdue
CREATE TYPE borrow_status AS ENUM ('pending', 'approved', 'rejected', 'borrowed', 'returned', 'overdue');

-- Return request status: Pending, Confirmed
CREATE TYPE return_status AS ENUM ('pending', 'confirmed');

-- Book condition: Normal (bình thường), Damaged (hư hỏng), Lost (mất)
CREATE TYPE book_condition AS ENUM ('normal', 'damaged', 'lost');

-- Fine type: Damaged, Lost, Overdue (trả muộn)
CREATE TYPE fine_type AS ENUM ('damaged', 'lost', 'overdue');

-- Fine status: Unpaid (chưa thanh toán), Pending Confirmation (chờ xác nhận), Paid (đã thanh toán), Rejected (từ chối)
CREATE TYPE fine_status AS ENUM ('unpaid', 'pending_confirmation', 'paid', 'rejected');

-- ============================================================================
-- TABLES (in dependency order)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Users Table
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(255),
    role user_role NOT NULL DEFAULT 'reader',
    status user_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT users_name_length CHECK (char_length(name) > 0 AND char_length(name) <= 50),
    CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

COMMENT ON TABLE users IS 'User accounts for the library management system';
COMMENT ON COLUMN users.role IS 'User role: reader (độc giả), librarian (nhân viên), admin (quản lý viên)';
COMMENT ON COLUMN users.status IS 'Account status: pending (chờ xác nhận), active (kích hoạt), disabled (vô hiệu hóa)';

-- ----------------------------------------------------------------------------
-- Book Categories Table
-- ----------------------------------------------------------------------------
CREATE TABLE book_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT book_categories_name_length CHECK (char_length(name) > 0 AND char_length(name) <= 50)
);

COMMENT ON TABLE book_categories IS 'Categories for organizing books';

-- ----------------------------------------------------------------------------
-- Books Table
-- ----------------------------------------------------------------------------
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES book_categories(id) ON DELETE RESTRICT,
    title VARCHAR(100) NOT NULL,
    author VARCHAR(100) NOT NULL,
    isbn VARCHAR(17), -- ISBN-10 (10 chars) or ISBN-13 (13 chars with hyphens)
    publication_year INTEGER NOT NULL,
    description VARCHAR(255) NOT NULL,
    total_copies INTEGER NOT NULL DEFAULT 0,
    available_copies INTEGER NOT NULL DEFAULT 0,
    borrowed_count INTEGER NOT NULL DEFAULT 0, -- For popularity tracking
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT books_title_length CHECK (char_length(title) > 0 AND char_length(title) <= 100),
    CONSTRAINT books_author_length CHECK (char_length(author) > 0 AND char_length(author) <= 100),
    CONSTRAINT books_description_length CHECK (char_length(description) > 0 AND char_length(description) <= 255),
    CONSTRAINT books_publication_year CHECK (publication_year >= 1900 AND publication_year <= EXTRACT(YEAR FROM now())::INTEGER),
    CONSTRAINT books_total_copies CHECK (total_copies > 0),
    CONSTRAINT books_available_copies CHECK (available_copies >= 0),
    CONSTRAINT books_copies_logic CHECK (available_copies <= total_copies),
    CONSTRAINT books_borrowed_count CHECK (borrowed_count >= 0)
);

COMMENT ON TABLE books IS 'Book catalog information';
COMMENT ON COLUMN books.borrowed_count IS 'Counter for tracking book popularity based on borrow frequency';

-- ----------------------------------------------------------------------------
-- Borrow Requests Table
-- ----------------------------------------------------------------------------
CREATE TABLE borrow_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
    status borrow_status NOT NULL DEFAULT 'pending',
    request_date DATE NOT NULL DEFAULT CURRENT_DATE,
    borrow_date DATE,
    due_date DATE,
    extended BOOLEAN NOT NULL DEFAULT false,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT borrow_requests_due_date_logic CHECK (
        (due_date IS NULL) OR 
        (borrow_date IS NOT NULL AND due_date IS NOT NULL AND due_date >= borrow_date AND (due_date - borrow_date) <= 30)
    ),
    CONSTRAINT borrow_requests_extended_logic CHECK (
        (extended = false) OR 
        (borrow_date IS NOT NULL AND due_date IS NOT NULL)
    )
);

COMMENT ON TABLE borrow_requests IS 'Book borrowing requests and transactions';
COMMENT ON COLUMN borrow_requests.status IS 'Request status: pending, approved, rejected, borrowed, returned, overdue';
COMMENT ON COLUMN borrow_requests.extended IS 'Indicates if the borrow period has been extended (max 1 extension of +7 days)';
COMMENT ON COLUMN borrow_requests.rejection_reason IS 'Reason provided when borrow request is rejected';

-- ----------------------------------------------------------------------------
-- Return Requests Table
-- ----------------------------------------------------------------------------
CREATE TABLE return_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borrow_request_id UUID NOT NULL REFERENCES borrow_requests(id) ON DELETE CASCADE,
    status return_status NOT NULL DEFAULT 'pending',
    request_date DATE NOT NULL DEFAULT CURRENT_DATE,
    confirmed_date TIMESTAMP WITH TIME ZONE,
    condition book_condition,
    confirmed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT return_requests_notes_length CHECK (notes IS NULL OR char_length(notes) <= 500),
    CONSTRAINT return_requests_condition_required CHECK (
        (condition IS NULL AND status = 'pending') OR 
        (condition IS NOT NULL AND status = 'confirmed')
    ),
    CONSTRAINT return_requests_one_pending_per_borrow UNIQUE (borrow_request_id, status) 
        WHERE status = 'pending'
);

COMMENT ON TABLE return_requests IS 'Return requests for borrowed books';
COMMENT ON COLUMN return_requests.condition IS 'Book condition: normal (bình thường), damaged (hư hỏng), lost (mất)';
COMMENT ON COLUMN return_requests.notes IS 'Notes about book condition, required when condition is damaged or lost';

-- ----------------------------------------------------------------------------
-- Fine Levels Table
-- ----------------------------------------------------------------------------
CREATE TABLE fine_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(25) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT fine_levels_name_length CHECK (char_length(name) > 0 AND char_length(name) <= 25),
    CONSTRAINT fine_levels_amount_positive CHECK (amount > 0)
);

COMMENT ON TABLE fine_levels IS 'Fine level configurations managed by administrators';

-- ----------------------------------------------------------------------------
-- Fines Table
-- ----------------------------------------------------------------------------
CREATE TABLE fines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    return_request_id UUID REFERENCES return_requests(id) ON DELETE SET NULL,
    fine_level_id UUID NOT NULL REFERENCES fine_levels(id) ON DELETE RESTRICT,
    type fine_type NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    status fine_status NOT NULL DEFAULT 'unpaid',
    fine_date DATE NOT NULL DEFAULT CURRENT_DATE,
    rejection_reason TEXT,
    confirmed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT fines_amount_positive CHECK (amount > 0),
    CONSTRAINT fines_return_request_logic CHECK (
        (return_request_id IS NULL AND type = 'overdue') OR 
        (return_request_id IS NOT NULL AND type IN ('damaged', 'lost'))
    )
);

COMMENT ON TABLE fines IS 'Fine records for damaged books, lost books, and overdue returns';
COMMENT ON COLUMN fines.type IS 'Fine type: damaged, lost, overdue (trả muộn)';
COMMENT ON COLUMN fines.status IS 'Payment status: unpaid (chưa thanh toán), pending_confirmation (chờ xác nhận), paid (đã thanh toán), rejected (từ chối)';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Unique Indexes
-- ----------------------------------------------------------------------------
CREATE UNIQUE INDEX idx_users_email_unique ON users(email);
CREATE UNIQUE INDEX idx_book_categories_name_unique ON book_categories(name);

-- ----------------------------------------------------------------------------
-- Foreign Key Indexes
-- ----------------------------------------------------------------------------
CREATE INDEX idx_books_category_id ON books(category_id);
CREATE INDEX idx_borrow_requests_user_id ON borrow_requests(user_id);
CREATE INDEX idx_borrow_requests_book_id ON borrow_requests(book_id);
CREATE INDEX idx_return_requests_borrow_request_id ON return_requests(borrow_request_id);
CREATE INDEX idx_return_requests_confirmed_by ON return_requests(confirmed_by);
CREATE INDEX idx_fines_user_id ON fines(user_id);
CREATE INDEX idx_fines_return_request_id ON fines(return_request_id);
CREATE INDEX idx_fines_fine_level_id ON fines(fine_level_id);
CREATE INDEX idx_fines_confirmed_by ON fines(confirmed_by);

-- ----------------------------------------------------------------------------
-- Status Indexes (for filtering)
-- ----------------------------------------------------------------------------
CREATE INDEX idx_borrow_requests_status ON borrow_requests(status);
CREATE INDEX idx_return_requests_status ON return_requests(status);
CREATE INDEX idx_fines_status ON fines(status);

-- ----------------------------------------------------------------------------
-- Composite Indexes (for common query patterns)
-- ----------------------------------------------------------------------------
-- User's borrowing history filtered by status
CREATE INDEX idx_borrow_requests_user_status ON borrow_requests(user_id, status);

-- Book availability checks
CREATE INDEX idx_borrow_requests_book_status ON borrow_requests(book_id, status);

-- Overdue detection: borrowed books past due date
CREATE INDEX idx_borrow_requests_due_date_borrowed 
    ON borrow_requests(due_date) 
    WHERE status = 'borrowed';

-- User's unpaid/pending fines
CREATE INDEX idx_fines_user_status ON fines(user_id, status) 
    WHERE status IN ('unpaid', 'pending_confirmation');

-- Book listing with category and availability filters
CREATE INDEX idx_books_category_available ON books(category_id, available_copies);

-- Search by title and author (B-tree for prefix matching)
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author);

-- Full-text search indexes (GIN for better search performance)
CREATE INDEX idx_books_title_gin ON books USING gin(to_tsvector('english', title));
CREATE INDEX idx_books_author_gin ON books USING gin(to_tsvector('english', author));

-- Trigram indexes for fuzzy search (useful for Vietnamese text)
CREATE INDEX idx_books_title_trgm ON books USING gin(title gin_trgm_ops);
CREATE INDEX idx_books_author_trgm ON books USING gin(author gin_trgm_ops);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function: Update updated_at timestamp
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Triggers: Auto-update updated_at
-- ----------------------------------------------------------------------------
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_categories_updated_at BEFORE UPDATE ON book_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_borrow_requests_updated_at BEFORE UPDATE ON borrow_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_return_requests_updated_at BEFORE UPDATE ON return_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fine_levels_updated_at BEFORE UPDATE ON fine_levels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fines_updated_at BEFORE UPDATE ON fines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Function: Update book available_copies when borrow status changes
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_book_availability()
RETURNS TRIGGER AS $$
BEGIN
    -- When status changes to 'borrowed', decrease available_copies
    IF NEW.status = 'borrowed' AND (OLD.status IS NULL OR OLD.status != 'borrowed') THEN
        UPDATE books 
        SET available_copies = available_copies - 1,
            borrowed_count = borrowed_count + 1
        WHERE id = NEW.book_id;
    END IF;

    -- When status changes from 'borrowed' to something else, increase available_copies
    IF OLD.status = 'borrowed' AND NEW.status != 'borrowed' AND NEW.status != 'pending' THEN
        UPDATE books 
        SET available_copies = available_copies + 1
        WHERE id = NEW.book_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_book_availability_trigger 
    AFTER INSERT OR UPDATE OF status ON borrow_requests
    FOR EACH ROW EXECUTE FUNCTION update_book_availability();

-- ----------------------------------------------------------------------------
-- Function: Check and update overdue status
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_overdue_borrows()
RETURNS void AS $$
BEGIN
    UPDATE borrow_requests
    SET status = 'overdue'
    WHERE status = 'borrowed'
      AND due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_overdue_borrows() IS 'Updates borrow status to overdue for books past due date';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE return_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE fine_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE fines ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Note: These policies assume Supabase auth is being used.
-- If using a different auth system, replace auth.uid() with your auth function.
-- For now, we'll use placeholder policies that can be customized.

-- ----------------------------------------------------------------------------
-- Users Table Policies
-- ----------------------------------------------------------------------------
-- Users can read their own profile
CREATE POLICY "Users can read own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile (except role and status)
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id AND
        role = OLD.role AND
        status = OLD.status
    );

-- Admins can read all users
CREATE POLICY "Admins can read all users"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        )
    );

-- Admins and librarians can update users
CREATE POLICY "Admins and librarians can update users"
    ON users FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'librarian') AND status = 'active'
        )
    );

-- ----------------------------------------------------------------------------
-- Book Categories Table Policies
-- ----------------------------------------------------------------------------
-- Everyone can read book categories (public access)
CREATE POLICY "Anyone can read book categories"
    ON book_categories FOR SELECT
    USING (true);

-- Only librarians and admins can modify categories
CREATE POLICY "Librarians and admins can manage categories"
    ON book_categories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- ----------------------------------------------------------------------------
-- Books Table Policies
-- ----------------------------------------------------------------------------
-- Everyone can read books (public access for browsing)
CREATE POLICY "Anyone can read books"
    ON books FOR SELECT
    USING (true);

-- Only librarians and admins can modify books
CREATE POLICY "Librarians and admins can manage books"
    ON books FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- ----------------------------------------------------------------------------
-- Borrow Requests Table Policies
-- ----------------------------------------------------------------------------
-- Users can read their own borrow requests
CREATE POLICY "Users can read own borrow requests"
    ON borrow_requests FOR SELECT
    USING (user_id = auth.uid());

-- Readers can create borrow requests
CREATE POLICY "Readers can create borrow requests"
    ON borrow_requests FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'reader' AND status = 'active'
        )
    );

-- Librarians and admins can read all borrow requests
CREATE POLICY "Librarians and admins can read all borrow requests"
    ON borrow_requests FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- Librarians and admins can update borrow requests (approve/reject)
CREATE POLICY "Librarians and admins can update borrow requests"
    ON borrow_requests FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- ----------------------------------------------------------------------------
-- Return Requests Table Policies
-- ----------------------------------------------------------------------------
-- Users can read return requests for their own borrows
CREATE POLICY "Users can read own return requests"
    ON return_requests FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM borrow_requests
            WHERE borrow_requests.id = return_requests.borrow_request_id
            AND borrow_requests.user_id = auth.uid()
        )
    );

-- Users can create return requests for their own borrows
CREATE POLICY "Users can create return requests"
    ON return_requests FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM borrow_requests
            WHERE borrow_requests.id = return_requests.borrow_request_id
            AND borrow_requests.user_id = auth.uid()
            AND borrow_requests.status = 'borrowed'
        )
    );

-- Librarians and admins can read all return requests
CREATE POLICY "Librarians and admins can read all return requests"
    ON return_requests FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- Librarians and admins can update return requests (confirm return)
CREATE POLICY "Librarians and admins can update return requests"
    ON return_requests FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- ----------------------------------------------------------------------------
-- Fine Levels Table Policies
-- ----------------------------------------------------------------------------
-- Everyone can read fine levels (for transparency)
CREATE POLICY "Anyone can read fine levels"
    ON fine_levels FOR SELECT
    USING (true);

-- Only admins can manage fine levels
CREATE POLICY "Admins can manage fine levels"
    ON fine_levels FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        )
    );

-- ----------------------------------------------------------------------------
-- Fines Table Policies
-- ----------------------------------------------------------------------------
-- Users can read their own fines
CREATE POLICY "Users can read own fines"
    ON fines FOR SELECT
    USING (user_id = auth.uid());

-- Users can update their own fines (mark as paid - pending confirmation)
CREATE POLICY "Users can update own fines to pending"
    ON fines FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (
        user_id = auth.uid() AND
        (OLD.status = 'unpaid' AND NEW.status = 'pending_confirmation')
    );

-- Librarians and admins can read all fines
CREATE POLICY "Librarians and admins can read all fines"
    ON fines FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- Librarians and admins can create fines (when confirming returns)
CREATE POLICY "Librarians and admins can create fines"
    ON fines FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- Librarians and admins can update fines (confirm payment or reject)
CREATE POLICY "Librarians and admins can update fines"
    ON fines FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('librarian', 'admin') AND status = 'active'
        )
    );

-- ============================================================================
-- INITIAL DATA (Optional - for development/testing)
-- ============================================================================

-- Uncomment to create initial admin user (password should be hashed properly in production)
-- INSERT INTO users (email, password_hash, name, role, status) 
-- VALUES ('admin@library.com', '$2b$10$your-hashed-password-here', 'Admin User', 'admin', 'active');

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. This schema assumes Supabase authentication is being used.
--    If using a different auth system, replace auth.uid() with your auth function.

-- 2. Password hashing should be done at the application level before inserting into the database.

-- 3. The update_book_availability trigger automatically maintains available_copies.
--    Ensure triggers are working correctly in your environment.

-- 4. The check_overdue_borrows() function should be called periodically (e.g., via cron job)
--    to update overdue statuses.

-- 5. Business rules enforced at application level:
--    - Maximum borrow limit (5 books per user)
--    - Maximum borrow period (30 days)
--    - Extension limit (1 time, +7 days)
--    - Validation of fine amount matches fine_level amount

-- 6. For production, consider:
--    - Adding audit logging
--    - Implementing soft deletes where appropriate
--    - Adding more comprehensive indexes based on query patterns
--    - Setting up database backups
--    - Monitoring query performance

