-- Add up migration script here
CREATE TABLE replies (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    agree BOOLEAN NOT NULL
)
