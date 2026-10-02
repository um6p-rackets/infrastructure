-- ==========================================
-- 1. BASE TABLES (No Foreign Keys)
-- ==========================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    login VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    gender BOOLEAN NOT NULL,                -- True (Male) , False (Female) ONLY
    department TEXT NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    avatar TEXT NOT NULL,
    joined_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clubs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    avatar TEXT NOT NULL,
    created_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. RELATIONSHIP TABLES (Dependent on Base)
-- ==========================================

CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role INTEGER NOT NULL DEFAULT 0, -- 0 represents 'member' in your backend ENUM
    joined_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX members_club_id_index ON members(club_id);
CREATE INDEX members_user_id_index ON members(user_id);

CREATE TABLE week_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    day_name INTEGER NOT NULL,
    start_time TIME(0) WITHOUT TIME ZONE NOT NULL,
    end_time TIME(0) WITHOUT TIME ZONE NOT NULL,
    total_attends BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX week_sessions_club_id_index ON week_sessions(club_id);

CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    player1_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    player2_id UUID REFERENCES members(id) ON DELETE CASCADE, -- Nullable for 1v1
    created_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX teams_club_id_index ON teams(club_id);
CREATE INDEX teams_player1_id_index ON teams(player1_id);
CREATE INDEX teams_player2_id_index ON teams(player2_id);

-- ==========================================
-- 3. COMPLEX ENTITIES (Dependent on Relationships)
-- ==========================================

CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    team1_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    team2_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    winner_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    ref_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    team1_score INTEGER NOT NULL DEFAULT 0,
    team2_score INTEGER NOT NULL DEFAULT 0,
    team1_points INTEGER NOT NULL DEFAULT 0,
    team2_points INTEGER NOT NULL DEFAULT 0,
    mode INTEGER NOT NULL,
    scheduled_at TIMESTAMP(0) WITH TIME ZONE NOT NULL
);
CREATE INDEX matches_club_id_index ON matches(club_id);
CREATE INDEX matches_team1_id_index ON matches(team1_id);
CREATE INDEX matches_team2_id_index ON matches(team2_id);
CREATE INDEX matches_winner_id_index ON matches(winner_id);

CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    taken_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX achievements_club_id_index ON achievements(club_id);
CREATE INDEX achievements_user_id_index ON achievements(user_id);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    sender_club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    sender_type VARCHAR(100) NOT NULL,
    notif_category INTEGER NOT NULL DEFAULT 0, -- 0 represents 'club_notification' in ENUM
    sent_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX notifications_sender_member_id_index ON notifications(sender_member_id);
CREATE INDEX notifications_sender_club_id_index ON notifications(sender_club_id);

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    description TEXT NOT NULL,
    announcer_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    created_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX announcements_announcer_id_index ON announcements(announcer_id);
CREATE INDEX announcements_club_id_index ON announcements(club_id);

CREATE TABLE session_attends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES week_sessions(id) ON DELETE CASCADE,
    created_at TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX session_attends_member_id_index ON session_attends(member_id);
CREATE INDEX session_attends_session_id_index ON session_attends(session_id);

CREATE TABLE notification_receivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    receiver_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    action BOOLEAN NOT NULL DEFAULT false
);
CREATE INDEX notification_receivers_notification_id_index ON notification_receivers(notification_id);
CREATE INDEX notification_receivers_receiver_user_id_index ON notification_receivers(receiver_user_id);