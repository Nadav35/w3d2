-- PRAGMA foreign_keys = ON;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO 
  users (fname, lname)
VALUES
  ('Nadav', 'Noy'),
  ('Rex', 'Bodoia');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('Do you like soccer?', "Hell no, its fucking boring", (SELECT id FROM users WHERE fname = 'Nadav')),
  ('Do you like CSS?', "Hell no, its fucking complicated", (SELECT id FROM users WHERE fname = 'Rex'));

INSERT INTO 
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Nadav'),
  (SELECT id from questions where title = 'Do you like CSS?')),
  ((SELECT id FROM users WHERE fname = 'Rex'),
  (SELECT id from questions where title = 'Do you like soccer?'));
  
INSERT INTO
  replies (question_id, parent_id, user_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = "Do you like soccer?"),
  NULL,
  (SELECT id FROM users WHERE fname = "Nadav" AND lname = "Noy"),
   "Did you say NOW NOW NOW?"
);

INSERT INTO
  replies (question_id, parent_id, user_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'Do you like CSS?'),
  (SELECT id FROM replies WHERE body = "Hell no, its fucking complicated"),
  (SELECT id FROM users WHERE fname = "Rex" AND lname = "Bodoia"),
  "I think he said MEOW MEOW MEOW."
  );
    