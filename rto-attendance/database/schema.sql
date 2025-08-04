-- RTO Attendance Tracking System Database Schema

-- Enable foreign key constraints (SQLite)
PRAGMA foreign_keys = ON;

-- Team members table
CREATE TABLE IF NOT EXISTS team_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    full_name TEXT GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email TEXT,
    work_schedule TEXT,
    aws_day TEXT,
    department TEXT DEFAULT 'RTO',
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Pay periods table
CREATE TABLE IF NOT EXISTS pay_periods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    period_name TEXT NOT NULL,
    period_number INTEGER,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(period_name, start_date)
);

-- Attendance records table
CREATE TABLE IF NOT EXISTS attendance_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_member_id INTEGER NOT NULL,
    pay_period_id INTEGER NOT NULL,
    attendance_date DATE NOT NULL,
    status_code TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    FOREIGN KEY (team_member_id) REFERENCES team_members(id) ON DELETE CASCADE,
    FOREIGN KEY (pay_period_id) REFERENCES pay_periods(id) ON DELETE CASCADE,
    UNIQUE(team_member_id, pay_period_id, attendance_date)
);

-- Reason codes table
CREATE TABLE IF NOT EXISTS reason_codes (
    code TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    category TEXT,
    color_code TEXT,
    is_active BOOLEAN DEFAULT 1,
    display_order INTEGER DEFAULT 0
);

-- Audit log table
CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    record_id INTEGER NOT NULL,
    action TEXT NOT NULL, -- INSERT, UPDATE, DELETE
    old_values TEXT, -- JSON
    new_values TEXT, -- JSON
    changed_by TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_attendance_team_period ON attendance_records(team_member_id, pay_period_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(attendance_date);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance_records(status_code);
CREATE INDEX IF NOT EXISTS idx_team_members_active ON team_members(is_active);
CREATE INDEX IF NOT EXISTS idx_team_members_employee_id ON team_members(employee_id);
CREATE INDEX IF NOT EXISTS idx_pay_periods_dates ON pay_periods(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_pay_periods_active ON pay_periods(is_active);

-- Triggers for updated_at timestamps
CREATE TRIGGER IF NOT EXISTS update_team_members_timestamp 
    AFTER UPDATE ON team_members
    FOR EACH ROW
    BEGIN
        UPDATE team_members SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

CREATE TRIGGER IF NOT EXISTS update_attendance_records_timestamp 
    AFTER UPDATE ON attendance_records
    FOR EACH ROW
    BEGIN
        UPDATE attendance_records SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;
