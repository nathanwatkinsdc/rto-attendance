-- Seed data for RTO Attendance Tracking System

-- Insert reason codes
INSERT OR REPLACE INTO reason_codes (code, description, category, color_code, display_order) VALUES
('AL', 'Approved Leave (annual, sick, family sick leave, bereavement)', 'Leave', '#f39c12', 1),
('AWS', 'Flex Day (* indicates switch from official work schedule; AWS indicates regular day)', 'Flex', '#3498db', 2),
('JD', 'Jury Duty', 'Civic', '#9b59b6', 3),
('PA', 'Pre-approved non-building location', 'Remote', '#2ecc71', 4),
('LOC1', 'Working at Location 1', 'External', '#e74c3c', 5),
('LOC2', 'Working at Location 2', 'External', '#e67e22', 6),
('LOC3', 'Working at Location 3 (incl. travel to/from)', 'External', '#1abc9c', 7),
('LOC4', 'Working at Location 4', 'External', '#34495e', 8),
('OST', 'Off-Site Training (incl conferences)', 'Training', '#f1c40f', 9),
('OSM', 'Off-Site Meeting (incl. interagency meetings)', 'Meeting', '#95a5a6', 10);

-- Insert sample team members (based on your screenshot)
INSERT OR REPLACE INTO team_members (employee_id, first_name, last_name, email, work_schedule, aws_day) VALUES
('CC001', 'Charles', 'C', 'charles.c@agency.gov', 'MF / 8-5:30', '2nd Tues'),
('PG001', 'Paula', 'G', 'paula.g@agency.gov', 'F / 6:30-3', 'No'),
('YG001', 'Yeezy', 'G', 'yeezy.g@agency.gov', 'MF / 7-5', '1st Fri'),
('BH001', 'Billy', 'H', 'billy.h@agency.gov', 'MF / 8:15-5:45', '2nd Wed'),
('MJ001', 'Maureen', 'J', 'maureen.j@agency.gov', 'F / 6:45-3:15', 'No'),
('BK001', 'Bucky', 'K', 'bucky.k@agency.gov', 'MF/8:00-6:30', '1st+2nd Fri'),
('CL001', 'Cynthia', 'L', 'cynthiaarol.l@agency.gov', 'MF / 9:15-7:45', '1st+2nd Fri'),
('KM001', 'Kris', 'M', 'kris.m@agency.gov', 'F / 8:30-5:00', 'No'),
('DM001', 'Davey', 'M', 'davey.m@agency.gov', 'MF / 8:30-6', '2nd Fri'),
('QM001', 'Quark', 'M', 'quark.m@agency.gov', 'MF / 8-5:30', '2nd Fri'),
('CN001', 'Chip', 'N', 'chip.n@agency.gov', 'F / 7-3:30', 'No'),
('IN001', 'Ivy', 'N', 'ivy.n@agency.gov', 'MF / 7-4:30', '2nd Tues'),
('SP001', 'Soup', 'P', 'soup.p@agency.gov', 'F / 8-4:30', 'No'),
('DS001', 'Domino', 'S', 'domino.s@agency.gov', 'F / 8:45-5:15', 'No'),
('NS001', 'Navy', 'S', 'navy.s@agency.gov', 'F / 8-4:30', 'No'),
('AT001', 'Anola', 'T', 'anola.t@agency.gov', 'MF / 7-4:30', '2nd Fri'),
('BW001', 'Butter', 'W', 'butter.w@agency.gov', 'F / 8:45-5:15', 'No'),
('NW001', 'Nathan', 'W', 'nathan.w@agency.gov', 'MF / 8:30-6', '2nd Fri'),
('CY001', 'Charizard', 'Y', 'charizard.y@agency.gov', 'MF / 7-4:30', '1st Mon'),
('MZ001', 'Melon', 'Z', 'melon.z@agency.gov', 'MF / 8-5:30', '1st Fri');

-- Insert sample pay periods
INSERT OR REPLACE INTO pay_periods (period_name, period_number, start_date, end_date, is_active) VALUES
('PP 17 (July 28 - August 8)', 17, '2025-07-28', '2025-08-08', 1),
('PP 18 (August 11 - August 22)', 18, '2025-08-11', '2025-08-22', 1),
('PP 19 (August 25 - September 5)', 19, '2025-08-25', '2025-09-05', 1),
('PP 20 (September 8 - September 19)', 20, '2025-09-08', '2025-09-19', 1),
('PP 21 (September 22 - October 3)', 21, '2025-09-22', '2025-10-03', 1);