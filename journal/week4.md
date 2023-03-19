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

Create a file named 'db.py' under /backend-flask/lib
```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

Update docker-compose.yml file
```yml
CONNECTION_URL: "${PROD_CONNECTION_URL}"
```

Import db.py file in home_activities.py
```py
from lib.db import pool, query_wrap_array
```

Replace the hard-coded results with the following
```py
sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    """)
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()

    return json[0]
```

## Connect Gitpod to RDS Instance

1. Go to AWS RDS and go into the database called "cruddur-db-instance"
2. Go to "VPC Security group" and go to "Inbound rule"
3. Click "Edit Inbound rule" and add your GitPod IP

Before adding GitPod IP,

Run the following in the terminal
```sh
GITPOD_IP=$(curl ifconfig.me)
```
> This will capture the GITPOD IP address
> Then, we can run psql $PROD_CONNECTION_URL

However, this IP address changes whenever we launch a new work space
Therefore, we are going to set the security group ID to change the IP address automatically

Run the following in the terminal
```sh
export DB_SG_ID="sg-0b725ebab7e25635e"
gp env DB_SG_ID="sg-0b725ebab7e25635e"
export DB_SG_RULE_ID="sgr-070061bba156cfa88"
gp env DB_SG_RULE_ID="sgr-070061bba156cfa88"
```
> Make sure to set the right security group ID and security group Rule ID

Run the following in the terminal
```sh
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
> If it works correctly, the terminal will return "true"

Now create a file named "rds-update-sg-rule" under /backend-flask/bin
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rule"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
> Remember to change the permission
> chmod u+x ./bin/rds-update-sg-rule

Also update the gitpod.yml file so that it can run automatically whenever a new workspace is launched
```yml
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
```
> It has to be located under 'postgres'

Also update env var "CONNECTION_URL" in Docker-compose.yml
```yml
CONNECTION_URL: "${PROD_CONNECTION_URL}"
```

## Result from connect Gitpod to RDS Instance

<img src = "images/securitygroup.png" >

<img src = "images/prod.png" >


## Create Congito Trigger to insert user into database

During the Sign process, we need to insert the user's cognito user id into the database
It can happen using a AWS lambda funtion

Go to AWS Lambda and create a function
1. Select Author from scratch
2. Name the function "cruddur-post-confirmation"
3. Set the Runtime to Python 3.8 
4. Select x86-64 for Architecture

We also need to create a file to put the function code in our local environment
Create a file named "cruddur-post-confirmation.py" under /aws/lambdas
```py
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name = user['name']
    user_email        = user['email']
    user_handle       = user['preferred_username']
    user_cognito_id   = user['sub']

    try:
        sql = f"""
            INSERT INTO public.users (
                display_name,
                email,
                handle,
                cognito_user_id
            )
            VALUES(
                '{user_display_name}',
                '{user_email}',
                '{user_handle}',
                '{user_cognito_id}'
            )
        """
        print(sql)
        conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            cur.close()
            conn.close()
            print('Database connection closed.')

    return event
```
> Put the function code in the lambda function in AWS Console as well
> Click "Deploy" in the console

In the console, go to Configurations and Environment varaibles
Add env var
```sh
key: CONNECTION_URL
value: 
```
> value can be found by running env | grep PROD_CONNECTION_URL

Go back to Code and Layers and add a Layer
1. Select specify an ARN
2. Put the following
```sh
arn:aws:lambda:ca-central-1:898466741470:layer:psycopg2-py38:1
```
> Make sure to put the right region

Go to Cognito user pool and select the right user pool for user authorization
1. Go to User pool properties
2. Go to Lambda triggers
3. Select Add Lambda trigger
4. Select Sign-up
5. Select Post confirmation trigger
6. Choose the right lambda function

Before adding a VPC, we need to setup a security group and policies
1. Go to Lambda
2. Go to Configurations
3. Go to Permissions
4. Click Role name
5. Click Add permission and attach policies
6. Click create policy
7. Choose json and put the following
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
```
8. Name the policy "AWSLambdaVPCAccessExecutionRole"


After attaching the new policy,
1. Go to Configurations
2. Go to VPC
3. Click edit
4. Select a VPC available
5. Choose the subnets(I chose a abd b)
6. Set the security group(I used the default one)
7. Save


Go to Cloudwatch logs to check the logts if the function works as expected
1. Sign-up using a new username and password
2. Check the Cloudwatch logs if there is any error
3. Check if the user data is also in the databse

## Result from creating Congito Trigger to insert user into database

<img src = "images/lambda.png" >

## Create new activities with a database insert

Update /backend-flask/create_activity.py
```py

```


