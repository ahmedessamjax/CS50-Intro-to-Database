-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database
-- using gemini to generate data and insert them insdie the DATABASE;

-- -----------------------------------------------------------------------------
-- 1. INSERT SAMPLE USERS
-- -----------------------------------------------------------------------------
INSERT INTO `users` (
    `id`, `first_name`, `last_name`, `username`, `email`, `password_hash`, `bio`, `location`, `date_of_birth`
) VALUES 
(1, 'Alice', 'Smith', 'alicesmith', 'alice@example.com', '$2b$12$eImiTXuWVxfM37uY4JANjOQ.1N.M/m3B7z1L33g4h4K1M1K1M1K1M', 'Software Engineer & CS enthusiast.', 'Boston, MA', '1998-05-14'),
(2, 'Bob', 'Jones', 'bobjones', 'bob@example.com', '$2b$12$eImiTXuWVxfM37uY4JANjOQ.1N.M/m3B7z1L33g4h4K1M1K1M1K1M', 'Database nerd. Building cool things with MySQL.', 'New York, NY', '1995-10-22'),
(3, 'Charlie', 'Brown', 'charlieb', 'charlie@example.com', '$2b$12$eImiTXuWVxfM37uY4JANjOQ.1N.M/m3B7z1L33g4h4K1M1K1M1K1M', 'Learning CS50 SQL! Loving relational modeling.', 'Chicago, IL', '2001-01-30'),
(4, 'Diana', 'Prince', 'dianap', 'diana@example.com', '$2b$12$eImiTXuWVxfM37uY4JANjOQ.1N.M/m3B7z1L33g4h4K1M1K1M1K1M', 'Tech lead & open-source contributor.', 'San Francisco, CA', '1992-08-11');

-- -----------------------------------------------------------------------------
-- 2. INSERT TRENDS / HASHTAGS
-- -----------------------------------------------------------------------------
INSERT INTO `trends` (`id`, `name`) VALUES 
(1, 'CS50'),
(2, 'SQL'),
(3, 'DatabaseDesign'),
(4, 'WebDev');

-- -----------------------------------------------------------------------------
-- 3. INSERT ORIGINAL POSTS (Top-Level Posts)
-- -----------------------------------------------------------------------------
-- Post #1: Alice posts a text update
INSERT INTO `posts` (`id`, `user_id`, `content`) VALUES 
(1, 1, 'Just finished designing my relational database schema for my final project! #CS50 #SQL');

-- Post #2: Bob posts an update with media (content can be NULL or descriptive)
INSERT INTO `posts` (`id`, `user_id`, `content`) VALUES 
(2, 2, 'Check out this architecture diagram I drew for my backend system. #DatabaseDesign');

-- Post #3: Charlie posts a short thought
INSERT INTO `posts` (`id`, `user_id`, `content`) VALUES 
(3, 3, 'Recursive CTEs in MySQL are incredibly powerful once you get the hang of them.');

-- -----------------------------------------------------------------------------
-- 4. INSERT REPLIES & SHARES (Self-Referencing Foreign Keys)
-- -----------------------------------------------------------------------------
-- Post #4: Bob replies to Alice (parent_post_id = 1)
INSERT INTO `posts` (`id`, `user_id`, `content`, `parent_post_id`) VALUES 
(4, 2, 'Congrats Alice! What database engine are you using?', 1);

-- Post #5: Charlie replies to Bob''s comment (parent_post_id = 4 - nested reply)
INSERT INTO `posts` (`id`, `user_id`, `content`, `parent_post_id`) VALUES 
(5, 3, 'I think she is using MySQL based on her earlier post!', 4);

-- Post #6: Diana quote-shares Alice''s original post (original_post_id = 1)
INSERT INTO `posts` (`id`, `user_id`, `content`, `original_post_id`) VALUES 
(6, 4, 'Great work! CS50 SQL is an amazing course.', 1);

-- -----------------------------------------------------------------------------
-- 5. ATTACH MEDIA
-- -----------------------------------------------------------------------------
-- Linking an image to Bob''s post (#2)
INSERT INTO `media` (`post_id`, `media_url`, `media_type`) VALUES 
(2, 'https://storage.example.com/uploads/diagram_v1.png', 'image');

-- -----------------------------------------------------------------------------
-- 6. INSERT JUNCTION DATA (Likes, Bookmarks, Follows, Post_Trends)
-- -----------------------------------------------------------------------------
-- Likes
INSERT INTO `likes` (`user_id`, `post_id`) VALUES 
(2, 1), -- Bob liked Alice's post
(3, 1), -- Charlie liked Alice's post
(4, 1), -- Diana liked Alice's post
(1, 2), -- Alice liked Bob's post
(3, 2); -- Charlie liked Bob's post

-- Bookmarks
INSERT INTO `bookmarks` (`user_id`, `post_id`) VALUES 
(3, 1), -- Charlie saved Alice's post
(1, 2); -- Alice saved Bob's post

-- Follows (Directed Graph)
INSERT INTO `follows` (`follower_id`, `following_id`) VALUES 
(1, 2), -- Alice follows Bob
(1, 4), -- Alice follows Diana
(2, 1), -- Bob follows Alice (Mutual)
(3, 1), -- Charlie follows Alice
(3, 2), -- Charlie follows Bob
(4, 1); -- Diana follows Alice

-- Link Posts to Trends
INSERT INTO `post_trends` (`post_id`, `trends_id`) VALUES 
(1, 1), -- Post #1 tagged with #CS50
(1, 2), -- Post #1 tagged with #SQL
(2, 3); -- Post #2 tagged with #DatabaseDesign

-- -----------------------------------------------------------------------------
-- 7. INSERT PRIVATE MESSAGES
-- -----------------------------------------------------------------------------
INSERT INTO `messages` (`sender_id`, `receiver_id`, `content`, `is_read`) VALUES 
(1, 2, 'Hey Bob! Did you see my latest schema draft?', TRUE),
(2, 1, 'Yes! Looking clean. Make sure to add compound indexes on foreign keys.', TRUE),
(1, 2, 'Will do, thanks for the tip!', FALSE);

-- =============================================================================
-- CS50 SQL Final Project: Demonstration Queries
-- Database Engine: MySQL 8.0+ (Matching Your Exact Schema)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. SELECT QUERIES
-- -----------------------------------------------------------------------------

-- Query 1.1: Fetch Home Timeline for User #1
-- Retrieves top-level posts from followed users, excluding soft-deleted user accounts
SELECT 
    `p`.`id` AS `post_id`,
    `u`.`username` AS `author`,
    `p`.`content`,
    `p`.`created_at`
FROM `posts` AS `p`
JOIN `follows` AS `f` ON `p`.`user_id` = `f`.`following_id`
JOIN `users` AS `u` ON `p`.`user_id` = `u`.`id`
WHERE `f`.`follower_id` = 1
  AND `p`.`parent_post_id` IS NULL
  AND `u`.`deleted` = 0
ORDER BY `p`.`created_at` DESC;

-- Query 1.2: Fetch Comment Thread for Post #100
-- Retrieves all replies attached directly to a target post
SELECT 
    `c`.`id` AS `comment_id`,
    `u`.`username` AS `author`,
    `c`.`content`,
    `c`.`created_at`
FROM `posts` AS `c`
JOIN `users` AS `u` ON `c`.`user_id` = `u`.`id`
WHERE `c`.`parent_post_id` = 100
  AND `u`.`deleted` = 0
ORDER BY `c`.`created_at` ASC;

-- Query 1.3: Fetch Private Messaging History Between User #1 and User #2
SELECT 
    `id` AS `message_id`,
    `sender_id`,
    `receiver_id`,
    `content`,
    `is_read`,
    `created_at`
FROM `messages`
WHERE (`sender_id` = 1 AND `receiver_id` = 2)
   OR (`sender_id` = 2 AND `receiver_id` = 1)
ORDER BY `created_at` ASC;

-- Query 1.4: Query Your Deleted Users View
SELECT * FROM `deleted_users`;

-- Query 1.5: Query Your 24-Hour Trending Hashtags View
SELECT * FROM `trending_hashtags_24h`;

-- -----------------------------------------------------------------------------
-- 2. UPDATE QUERIES
-- -----------------------------------------------------------------------------

-- Query 2.1: Update User Profile Metadata
UPDATE `users`
SET 
    `bio` = 'Software engineer and SQL enthusiast.',
    `location` = 'Boston, MA',
    `profile_pic_url` = 'https://example.com/profiles/user_1.png'
WHERE `id` = 1 
  AND `deleted` = 0;

-- Query 2.2: Soft-Delete a User Account (Using your boolean flag)
UPDATE `users`
SET `deleted` = 1
WHERE `id` = 5;

-- Query 2.3: Mark Direct Messages as Read
UPDATE `messages`
SET `is_read` = TRUE
WHERE `receiver_id` = 1 
  AND `sender_id` = 2 
  AND `is_read` = FALSE;

-- Query 2.4: Edit Post Content
UPDATE `posts`
SET `content` = 'Updating my post content for CS50!'
WHERE `id` = 100 
  AND `user_id` = 1;

-- -----------------------------------------------------------------------------
-- 3. DELETE QUERIES
-- --------------------------------
-- Query 3.1: Unlike a Post
DELETE FROM `likes`
WHERE `user_id` = 1 
  AND `post_id` = 100;

-- Query 3.2: Remove a Saved Bookmark
DELETE FROM `bookmarks`
WHERE `user_id` = 1 
  AND `post_id` = 100;

-- Query 3.3: Unfollow a User
DELETE FROM `follows`
WHERE `follower_id` = 1 
  AND `following_id` = 2;

-- Query 3.4: Hard Delete a Specific Post
DELETE FROM `posts`
WHERE `id` = 105 
  AND `user_id` = 1;

-- Query 3.5: Hard Delete All Soft-Deleted Users (Triggers ON DELETE CASCADE across relations)
DELETE FROM `users`
WHERE `deleted` = 1;