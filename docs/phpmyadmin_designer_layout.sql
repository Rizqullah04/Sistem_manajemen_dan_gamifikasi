-- Layout modular untuk phpMyAdmin Designer database ormawa_app.
-- Jalankan pada database metadata `phpmyadmin`, bukan pada `ormawa_app`.
-- Script hanya mengganti empat halaman yang namanya diawali "Ormawa App -".

START TRANSACTION;

DELETE tc
FROM phpmyadmin.pma__table_coords AS tc
INNER JOIN phpmyadmin.pma__pdf_pages AS p
    ON p.page_nr = tc.pdf_page_number
WHERE p.db_name = 'ormawa_app'
  AND p.page_descr LIKE 'Ormawa App -%';

DELETE FROM phpmyadmin.pma__pdf_pages
WHERE db_name = 'ormawa_app'
  AND page_descr LIKE 'Ormawa App -%';

-- 1. Pengguna & Organisasi
INSERT INTO phpmyadmin.pma__pdf_pages (db_name, page_descr)
VALUES ('ormawa_app', 'Ormawa App - 01 Pengguna dan Organisasi');
SET @page_users = LAST_INSERT_ID();

INSERT INTO phpmyadmin.pma__table_coords
    (db_name, table_name, pdf_page_number, x, y)
VALUES
    ('ormawa_app', 'users', @page_users, 80, 220),
    ('ormawa_app', 'user_ormawa_memberships', @page_users, 430, 80),
    ('ormawa_app', 'ormawas', @page_users, 800, 220),
    ('ormawa_app', 'chats', @page_users, 430, 500);

-- 2. Manajemen Kegiatan
INSERT INTO phpmyadmin.pma__pdf_pages (db_name, page_descr)
VALUES ('ormawa_app', 'Ormawa App - 02 Manajemen Kegiatan');
SET @page_activities = LAST_INSERT_ID();

INSERT INTO phpmyadmin.pma__table_coords
    (db_name, table_name, pdf_page_number, x, y)
VALUES
    ('ormawa_app', 'ormawas', @page_activities, 60, 260),
    ('ormawa_app', 'kategori_kegiatans', @page_activities, 420, 40),
    ('ormawa_app', 'kegiatans', @page_activities, 420, 330),
    ('ormawa_app', 'dokumentasi_kegiatans', @page_activities, 820, 20),
    ('ormawa_app', 'verifikasis', @page_activities, 820, 260),
    ('ormawa_app', 'penilaians', @page_activities, 820, 520),
    ('ormawa_app', 'diskusis', @page_activities, 1220, 80),
    ('ormawa_app', 'like_kegiatans', @page_activities, 1220, 390),
    ('ormawa_app', 'users', @page_activities, 1580, 260);

-- 3. Voting
INSERT INTO phpmyadmin.pma__pdf_pages (db_name, page_descr)
VALUES ('ormawa_app', 'Ormawa App - 03 Voting');
SET @page_voting = LAST_INSERT_ID();

INSERT INTO phpmyadmin.pma__table_coords
    (db_name, table_name, pdf_page_number, x, y)
VALUES
    ('ormawa_app', 'kegiatans', @page_voting, 60, 80),
    ('ormawa_app', 'ormawas', @page_voting, 60, 500),
    ('ormawa_app', 'votings', @page_voting, 480, 260),
    ('ormawa_app', 'vote_details', @page_voting, 900, 260),
    ('ormawa_app', 'users', @page_voting, 1300, 260);

-- 4. Gamifikasi & Penghargaan
INSERT INTO phpmyadmin.pma__pdf_pages (db_name, page_descr)
VALUES ('ormawa_app', 'Ormawa App - 04 Gamifikasi dan Penghargaan');
SET @page_gamification = LAST_INSERT_ID();

INSERT INTO phpmyadmin.pma__table_coords
    (db_name, table_name, pdf_page_number, x, y)
VALUES
    ('ormawa_app', 'periods', @page_gamification, 60, 480),
    ('ormawa_app', 'activity_types', @page_gamification, 60, 900),
    ('ormawa_app', 'users', @page_gamification, 470, 40),
    ('ormawa_app', 'ormawas', @page_gamification, 470, 1080),
    ('ormawa_app', 'user_points', @page_gamification, 850, 20),
    ('ormawa_app', 'user_badges', @page_gamification, 850, 300),
    ('ormawa_app', 'point_histories', @page_gamification, 850, 610),
    ('ormawa_app', 'poin_logs', @page_gamification, 850, 1040),
    ('ormawa_app', 'organization_points', @page_gamification, 850, 1460),
    ('ormawa_app', 'ormawa_badges', @page_gamification, 1250, 20),
    ('ormawa_app', 'badges', @page_gamification, 1640, 20),
    ('ormawa_app', 'leaderboards', @page_gamification, 1250, 430),
    ('ormawa_app', 'leaderboard_details', @page_gamification, 1640, 430),
    ('ormawa_app', 'ormawa_award_results', @page_gamification, 1250, 980);

-- 5. Keseluruhan relasi database domain
INSERT INTO phpmyadmin.pma__pdf_pages (db_name, page_descr)
VALUES ('ormawa_app', 'Ormawa App - 05 Keseluruhan Relasi');
SET @page_all = LAST_INSERT_ID();

INSERT INTO phpmyadmin.pma__table_coords
    (db_name, table_name, pdf_page_number, x, y)
VALUES
    -- Pengguna dan organisasi
    ('ormawa_app', 'chats', @page_all, 40, 80),
    ('ormawa_app', 'user_ormawa_memberships', @page_all, 40, 480),
    ('ormawa_app', 'users', @page_all, 430, 300),
    ('ormawa_app', 'ormawas', @page_all, 430, 1050),

    -- Kegiatan dan interaksi
    ('ormawa_app', 'kategori_kegiatans', @page_all, 820, 80),
    ('ormawa_app', 'kegiatans', @page_all, 820, 620),
    ('ormawa_app', 'dokumentasi_kegiatans', @page_all, 1210, 40),
    ('ormawa_app', 'verifikasis', @page_all, 1210, 360),
    ('ormawa_app', 'penilaians', @page_all, 1210, 680),
    ('ormawa_app', 'diskusis', @page_all, 1210, 1030),
    ('ormawa_app', 'like_kegiatans', @page_all, 1210, 1370),

    -- Voting
    ('ormawa_app', 'votings', @page_all, 1600, 570),
    ('ormawa_app', 'vote_details', @page_all, 1990, 570),

    -- Periode dan perhitungan poin
    ('ormawa_app', 'periods', @page_all, 430, 1740),
    ('ormawa_app', 'activity_types', @page_all, 40, 2050),
    ('ormawa_app', 'poin_logs', @page_all, 820, 1610),
    ('ormawa_app', 'point_histories', @page_all, 820, 2050),
    ('ormawa_app', 'user_points', @page_all, 1210, 1740),
    ('ormawa_app', 'organization_points', @page_all, 1210, 2110),

    -- Badge, leaderboard, dan penghargaan
    ('ormawa_app', 'badges', @page_all, 1600, 1510),
    ('ormawa_app', 'user_badges', @page_all, 1990, 1300),
    ('ormawa_app', 'ormawa_badges', @page_all, 1990, 1680),
    ('ormawa_app', 'leaderboards', @page_all, 1600, 2050),
    ('ormawa_app', 'leaderboard_details', @page_all, 1990, 2050),
    ('ormawa_app', 'ormawa_award_results', @page_all, 2380, 1680);

COMMIT;
