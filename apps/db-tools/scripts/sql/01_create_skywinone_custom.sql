CREATE TABLE IF NOT EXISTS `event_queue` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `version` bigint NOT NULL,
  `created_by` varchar(254) CHARACTER SET UTF8MB4 COLLATE utf8mb4_swedish_ci NOT NULL,
  `date_created` datetime NOT NULL,
  `last_updated` datetime NOT NULL,
  `retry_attempts` bigint NOT NULL,
  `status` bigint NOT NULL,
  `updated_by` varchar(254) CHARACTER SET UTF8MB4 COLLATE utf8mb4_swedish_ci DEFAULT NULL,
  `event_type` varchar(254) CHARACTER SET UTF8MB4 COLLATE utf8mb4_swedish_ci NOT NULL,
  `event_data` text CHARACTER SET UTF8MB4 COLLATE utf8mb4_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4 COLLATE=utf8mb4_swedish_ci;
