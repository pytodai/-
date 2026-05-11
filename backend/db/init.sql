-- Initialize database
ALTER USER svoboden CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE svoboden TO svoboden;
GRANT ALL ON SCHEMA public TO svoboden;
