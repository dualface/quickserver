CREATE DATABASE testdb;
CREATE USER 'test'@'localhost' IDENTIFIED BY '123456'; 
GRANT ALL ON testdb.* TO 'test'@'localhost';
