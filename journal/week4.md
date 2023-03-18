# Week 4 — Postgres and RDS

## Create RDS Postgres Instance

Because creating RDS instance using AWS console is harder to do than using CLI,
we are doing it using CLI. 

Open the work environtment and enter the following
```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password huEE33z2Qvl383 \
  --allocated-storage 20 \
  --availability-zone ca-central-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```
> Remember to put the correct and personalized settings, such as password, availability-zone, or etc.

## Result from creating RDS instance

<img src = "images/RDS_Setup.png" >

> If there is no error, we can check json formatted confirmation commends will come up

<img src = "images/RDS.png" >

> Go to the AWS RDS and the created database can be found
> When you are not using it, you can temporarily stop running the database by setting it

### Check the database connection

After docker-compuse up, run following
```sh
psql -Upostgres --host localhost
```
> To list the databases, run "\l"

If you can connect to the databases locally, then create a database called 'cruddur'
```sh
CREATE DATABASE cruddur;
```
> When creating RDS instace, we created a database names 'cruddur'
> We need to also create one locally to make it one to one

Common PSQL commands
```sh
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```

> Reference: https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
> Reference: https://www.postgresql.org/docs/current/sql-createdatabase.html


## Bash scripting for common database actions

### Setup schema and env vars

Go to /backend-flask and create a folder called 'db' and a file called 'schema.sql'
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;
```

After then, run the following to check if the schema.sql works properly
```sh
psql cruddur < db/schema.sql -h localhost -U postgres
```
> Make sure to run it in /backend-flask

To work with databases better, make a environment variable for a short cut
```sh
export CONNECTION_URL = "postgresql://postgres:password@localhost:5432/cruddur"
gp env CONNECTION_URL = "postgresql://postgres:password@localhost:5432/cruddur"
export PROD_CONNECTION_URL = "postgresql://cruddurroot:password@endpoint:5432/cruddur"
gp env PROD_CONNECTION_URL = "postgresql://cruddurroot:password@endpoint:5432/cruddur"
```
> password is for the place for your password
> cruddurroot is the place for your user name
> endpoint can be found in AWS RDS console
> PROD_CONNECTION_URL is for production use

After then, run the following to test the env var
```sh
psql $CONNECTION_URL
```
> It will allow connecting to the database without putting any addition info such as password

### Set up bash scripts for database

Go to /backend-flask and create a folder called 'lib' and a file called 'db-create'
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<< "$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "CREATE DATABASE cruddur;"
```
> the location of bash can be found by running "whereis bash" in the terminal
> (sed 's/\/cruddur//g' <<< "$CONNECTION_URL") meaning : it is goint to remove 'crudddur' from the CONNECTION_URL string


Create a file called "db-drop"
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<< "$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "DROP DATABASE cruddur;"
```

Create a file called "db-schema-load"
```sh
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```
> realpath will automatically detect your current location to run schema.sql

Before testing them, we need to grant a permission to the file to enable them to run
Run the following
```sh
chmod u+x ./bin/db-create
chmod u+x ./bin/db-drop
chmod u+x ./bin/db-schema-load
ls -l ./bin
```
> After then, you can check the permissions are changed

Test if the files can be run correctly
```sh
./bin/db-create
./bin/db-drop
./bin/db-schema-load prod
```

## Result from setting up bash scripts for database

<img src = "images/chmod.png" >

<img src = "images/bash.png" >

> It was hagging after running './bin/db-schema-load' since I temporarily stoped RDS instance 

### Update schema and set up more bash scripts for database

Update /db/shcema.sql
```sql

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

Create a file called "seed.sql" under /db
```sql
-- this file was manually created
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' , 'abc@gmail.com', 'MOCK'),
  ('Andrew Bayko', 'bayko', 'def@gmail.com', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```
> This will be a seed data for the database 'cruddur'

Create a file called "db-connect" under /lib
```sh
#! /usr/bin/bash

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL
```

Create a file called 'db-seed' under /lib
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```

Create a file named 'db-sessions' under /bin
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-sessions"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

NO_DB_URL=$(sed 's/\/cruddur//g' <<<"$URL")
psql $NO_DB_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```

Create a file named 'db-setup' under /bin
```sh
#! /usr/bin/bash

-e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```


## Result from updating schema and setting up more bash scripts

Before running all of them, do not forget to change the permission

<img src = "images/bash3.png" >

<img src = "images/bash4.png" >

<img src = "images/bash5.png" >

<img src = "images/bash6.png" >

<img src = "images/bash7.png" >


## Install Postgres Driver in Backend Application

Update /backend-flask/requirements.txt
```sh
psycopg[binary]
psycopg[pool]
```

Run the following to install the two libraries
```
pip install -r requirements.txt
```


## Connect Gitpod to RDS Instance
## Create Congito Trigger to insert user into database
## Create new activities with a database insert


