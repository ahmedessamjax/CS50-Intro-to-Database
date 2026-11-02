-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it
CREATE TABLE `users` (
    `id` BIGINT AUTO_INCREMENT,
    `first_name` VARCHAR(50) NOT NULL,
    `last_name` VARCHAR(50) NOT NULL,
    `username` VARCHAR(30) NOT NULL UNIQUE,
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `bio` VARCHAR(160),
    `location` VARCHAR(100),
    `date_of_birth` DATE NOT NULL,
    `profile_pic_url` VARCHAR(2048),
    `background_pic_url` VARCHAR(2048),
    `join_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_login` TIMESTAMP NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE `posts` (
    `id` BIGINT AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `content` TEXT, -- Nullable to support media-only posts
    `parent_post_id` BIGINT NULL,   -- Non-null indicates a comment/reply
    `original_post_id` BIGINT NULL, -- Non-null indicates a share/repost
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`parent_post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`original_post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
);

CREATE TABLE `media` (
    `id` BIGINT AUTO_INCREMENT,
    `post_id` BIGINT NOT NULL,
    `media_url` VARCHAR(2048) NOT NULL,
    `media_type` VARCHAR(20) DEFAULT 'image',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
);

CREATE TABLE `likes` (
    `user_id` BIGINT NOT NULL,
    `post_id` BIGINT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `post_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
);

CREATE TABLE `bookmarks` (
    `user_id` BIGINT NOT NULL,
    `post_id` BIGINT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `post_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
);

CREATE TABLE `follows` (
    `follower_id` BIGINT NOT NULL,
    `following_id` BIGINT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`follower_id`, `following_id`),
    CONSTRAINT `chk_no_self_follow` CHECK (`follower_id` <> `following_id`),
    FOREIGN KEY (`follower_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`following_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
);

CREATE TABLE `messages` (
    `id` BIGINT AUTO_INCREMENT,
    `sender_id` BIGINT NOT NULL,
    `receiver_id` BIGINT NOT NULL,
    `content` TEXT NOT NULL,
    `is_read` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`sender_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`receiver_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
);

CREATE TABLE `trends` (
    `id` BIGINT AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

CREATE TABLE `post_trends` (
    `post_id` BIGINT NOT NULL,
    `trends_id` BIGINT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`post_id`, `trends_id`),
    FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`trends_id`) REFERENCES `trends`(`id`) ON DELETE CASCADE
);

-- allow soft deletion;
ALTER TABLE `users` 
ADD COLUMN `deleted` BOOLEAN DEFAULT 0;

-- INDEXING;
CREATE INDEX `idx_posts_user_created` ON `posts` (`user_id`, `created_at` DESC);
CREATE INDEX `idx_posts_parent` ON `posts` (`parent_post_id`);
CREATE INDEX `idx_messages_conversation` ON `messages` (`sender_id`, `receiver_id`, `created_at` DESC);
CREATE INDEX `idx_messages_unread` ON `messages` (`receiver_id`, `is_read`);
CREATE INDEX `idx_post_trends_window` ON `post_trends` (`created_at` DESC, `trends_id`);

-- VIEWS;
-- Calculates top trending hashtags within the last 24 hours
CREATE VIEW `trending_hashtags_24h` AS
SELECT 
    `t`.`id` AS `trend_id`,
    `t`.`name` AS `hashtag`,
    COUNT(`pt`.`post_id`) AS `posts_count_24h`
FROM `trends` AS `t`
JOIN `post_trends` AS `pt` ON `t`.`id` = `pt`.`trends_id`
WHERE `pt`.`created_at` >= NOW() - INTERVAL 24 HOUR
GROUP BY `t`.`id`, `t`.`name`
ORDER BY `posts_count_24h` DESC;

-- Show all my deleted Users;
CREATE View `deleted_users` AS
SELECT 
    `first_name`,
    `last_name`,
    `username`,
    `join_date`,
    `last_login`
FROM `users`
WHERE `deleted` = 1
ORDER BY `join_date`;