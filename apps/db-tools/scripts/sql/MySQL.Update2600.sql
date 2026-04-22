/*
	Copyright 2026 SkyWinner, Jesper Löfberg
	Environment: MySQL, verified with MySQL server 8
	Version support: This script requires SkyWin 23.5.2 or higher

	
    Prepares your SkyWin database for upgrade to version 26.0.0
	Reserve less than 1 minute for script execution time


	Comments:
		1. Always take a backup of your database before running scripts
		2. Change "my_db_name" to the name of your database before running the script
*/

USE `<my_db_name>`;

ALTER TABLE `Member` RENAME COLUMN `Year` TO `LicenseYear`;
ALTER TABLE `IntMemberhistory` RENAME COLUMN `Year` TO `LicenseYear`;
ALTER TABLE `Membercertificate` RENAME COLUMN `Year` TO `LicenseYear`;
ALTER TABLE `Memberinstruct` RENAME COLUMN `Year` TO `LicenseYear`;
ALTER TABLE `Memberlicense` RENAME COLUMN `Year` TO `LicenseYear`;

UPDATE `intSelectionrow` 
SET selectionRow = REPLACE(selectionRow, 'Year', 'LicenseYear')
WHERE  (SelectionRow LIKE '%Year>%' OR SelectionRow LIKE '%Year=%')
AND SelectionRow NOT LIKE '%LicenseYear%';

/*  Store version update */
UPDATE intDbinfo SET Dbversion='26.0.0';
INSERT INTO `intDbupdate` (`Dbversion`,`Userid`,`LastUpd`) VALUES ('26.0.0','SkyWin-script', Now());