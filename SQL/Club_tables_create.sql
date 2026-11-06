CREATE TABLE IF NOT EXISTS clubs (
    club_id   INTEGER PRIMARY KEY,
    club_name TEXT NOT NULL UNIQUE
);

INSERT INTO clubs (club_name)
SELECT DISTINCT club
FROM financials;


SELECT * FROM clubs;

CREATE TABLE IF NOT EXISTS line_items (
    line_item         TEXT PRIMARY KEY,
    category          TEXT NOT NULL,
);

INSERT  INTO line_items (line_item, category)
SELECT DISTINCT line_item, category
FROM financials;

select * from lin e_items

CREATE TABLE IF NOT EXISTS seasons (
    season     TEXT PRIMARY KEY,
    start_year INTEGER NOT NULL
);

INSERT INTO seasons (season, start_year)
SELECT DISTINCT season, CAST(SUBSTR(season, 1, 4) AS INTEGER)
FROM financials;

select * from seasons

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS club_financials (
    club_id      INTEGER NOT NULL REFERENCES clubs(club_id),
    season       TEXT    NOT NULL REFERENCES seasons(season),
    line_item    TEXT    NOT NULL REFERENCES line_items(line_item),
    amount_eur_m REAL,
    PRIMARY KEY (club_id, season, line_item)
);

INSERT INTO club_financials (club_id, season, line_item, amount_eur_m )
SELECT  clubs.club_id,
        financials.season,
        financials.line_item,
        CAST(NULLIF(financials.amount_eur_m, '') AS REAL) 
FROM financials
JOIN clubs ON financials.club = clubs.club_name;

select * from club_financials