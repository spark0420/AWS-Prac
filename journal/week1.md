# Week 1 — App Containerization

## Containerize Application (Dockerfiles, Docker Compose)

### Add Dockerfile to Backend folder

Create a Dockerfile in `backend-flask/`

```dockerfile
FROM python:3.10-slim-buster
WORKDIR /backend-flask
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY . .
ENV FLASK_ENV=development
EXPOSE ${PORT}
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]
```

- WORKDIR /backend-flask --> change the work directory to /backend-flask folder in the container
- COPY requirements.txt requirements.txt --> copy requirement.txt from outside of container to inside container
- RUN pip3 install -r requirements.txt --> #insstall python3 in the container to run the app
- COPY . . --> . means everything in the current directory(linux), first . means everything in /backend-flask(outside container), second . means everything in /backend-flask (inside container)
- ENV FLASK_ENV=development --> it will set the env variable in the container and will remain while the container is running
- CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"] --> to run the backend container

### Build Container

```sh
docker build -t  backend-flask ./backend-flask
```

### Run Container

There are many options that we can set environtment variables in the run commands
I chose the second option to run container

1. First export environment variables first and run container

```sh
export FRONTEND_URL="*"
export BACKEND_URL="*"
docker run --rm -p 4567:4567 -it backend-flask
unset FRONTEND_URL="*"
unset BACKEND_URL="*"
```
> --rm: If you set the --rm flag, Docker also removes the anonymous volumes associated with the container when the container is removed.
> -p: When set to true publish all exposed ports to the host interfaces. The default is false. If the operator uses -P (or -p) then Docker will make the exposed port accessible on the host and the ports will be available to any client that can reach the host. 
> -it: The -it instructs Docker to allocate a pseudo-TTY connected to the container's stdin; creating an interactive bash shell in the container.


2. Include the environment variable settings in the commands

```sh
docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask
docker run --rm -p 4567:4567 -it  -e FRONTEND_URL -e BACKEND_URL backend-flask
```

### Get Container Images 

```sh
docker images
```

### Get Running Container Ids

```sh
docker ps
```


### Add Dockerfile to FrontEnd folder

### Install NPM
run NPM Install before building the container since it needs to copy the contents of node_modules

```sh
cd frontend-react-js
npm i
```

### Create Docker File

Create a Dockerfile in `frontend-react-js/`

```Dockerfile
FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]
```

### Build Container

```sh
docker build -t frontend-react-js ./frontend-react-js
```

### Run Container

```sh
docker run -p 3000:3000 -d frontend-react-js
```
> When starting a Docker container, you must first decide if you want to run the container in the background in a “detached” mode or in the default foreground mode
> To start a container in detached mode, you use -d=true or just -d option.
> Without -d, a container will start in foreground mode


### Create Docker compose file

Create docker-compose.yml at the root of your project.
This is to run both backend and frontend containers at the same time.
Env vars are also included, so we don't need to worry about setting them in a run commends

```yaml
version: "3.8"
services:
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./backend-flask
    ports:
      - "4567:4567"
    volumes:
      - ./backend-flask:/backend-flask
  frontend-react-js:
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./frontend-react-js
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-react-js:/frontend-react-js

# the name flag is a hack to change the default prepend folder
# name when outputting the image names
networks: 
  internal-network:
    driver: bridge
    name: cruddur
```
> After then, we can simply right click the file and click 'compose up' to run it
> We can also do the same thing with a commends 'docker compose up'


## Document the Notification Endpoint for the OpenAI Document

When clicked the Notifications tap in the website, nothing came up
The purpose of this part is to connect backend data to show up in the page.

First, becuase we are using OpenAPI, we need to first update 'backend-flask/openapi-3.0.yml' file
By adding the part below, we can add an Notification endpoint for the OpenAI Document

```yaml
/api/activities/notifications:
    get:
      description: 'Return a feed of activity for all of those that I follow'
      tags:
        - activities
      parameters: []
      responses:
        '200':
          description: Returns an array of activities
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Activity'

```

## Write a Flask Backend Endpoint for Notifications

First, we need to create a 'notification_activities.py' file in 'backend-flask/servicies/'
This file specifies what kind of information is going to be retreived when the funtion is called.
(Entry point)

```py
from datetime import datetime, timedelta, timezone
class NotificationsActivities:
  def run():
    now = datetime.now(timezone.utc).astimezone()
    results = [{
      'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
      'handle':  'Goyang',
      'message': 'I am a cat!',
      'created_at': (now - timedelta(days=2)).isoformat(),
      'expires_at': (now + timedelta(days=5)).isoformat(),
      'likes_count': 5,
      'replies_count': 1,
      'reposts_count': 0,
      'replies': [{
        'uuid': '26e12864-1c26-5c3a-9658-97a10f8fea67',
        'reply_to_activity_uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
        'handle':  'Worf',
        'message': 'This post has no honor!',
        'likes_count': 0,
        'replies_count': 0,
        'reposts_count': 0,
        'created_at': (now - timedelta(days=2)).isoformat()
      }],
    }
    ]
    return results
```
> Because this format is very similar to the format that can be found in home_activities.py, I simply copied and paste with some edit


Second, in 'backend-flask/app.py' we need to include an endpoint for Notification 

Import the file above

```py
from services.notifications_activities import *
```

Add endpoint

```py
@app.route("/api/activities/notifications", methods=['GET'])
@cross_origin()
def data_notifications():
  data = NotificationsActivities.run()
  return data, 200
 ``` 

 > After these steps, open an webpage using the port 4567. 
 > Append '/api/activities/notifications' these at the end of the address.
 > If information is not seen, we might need to restart the application again.


## Write a React Page for Notifications

When creating an Notification endpoint in Backend is done, we need to add one in the frontend too
because we need to see the retrieved information from the frontend too

First, create file 'NotificationsFeedPage.js" and "NotificationsFeedPage.css" in 
'frontend-react-js/src/pages'

'NotificationsFeedPage.js"

```js
import './NotificationsFeedPage.css';
import React from "react";

import DesktopNavigation  from '../components/DesktopNavigation';
import DesktopSidebar     from '../components/DesktopSidebar';
import ActivityFeed from '../components/ActivityFeed';
import ActivityForm from '../components/ActivityForm';
import ReplyForm from '../components/ReplyForm';

// [TODO] Authenication
import Cookies from 'js-cookie'

export default function NotificationsFeedPage() {
  const [activities, setActivities] = React.useState([]);
  const [popped, setPopped] = React.useState(false);
  const [poppedReply, setPoppedReply] = React.useState(false);
  const [replyActivity, setReplyActivity] = React.useState({});
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/notifications`
      const res = await fetch(backend_url, {
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };

  const checkAuth = async () => {
    console.log('checkAuth')
    // [TODO] Authenication
    if (Cookies.get('user.logged_in')) {
      setUser({
        display_name: Cookies.get('user.name'),
        handle: Cookies.get('user.username')
      })
    }
  };

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth();
  }, [])

  return (
    <article>
      <DesktopNavigation user={user} active={'notifications'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm  
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <ActivityFeed 
          title="Notifications" 
          setReplyActivity={setReplyActivity} 
          setPopped={setPoppedReply} 
          activities={activities} 
        />
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
}
```
> I simply copied contents from "HomeFeedPage.js" and changed some parts so that the contents match the Notification page
> I just empty the css file


Second, we need to add these information in the entry point('front-react-js/src/App.js')

import the file above

```py
import NotificationsFeedPage from './pages/NotificationsFeedPage';
```

Add information for the path

```py
  {
    path: "/notifications",
    element: <NotificationsFeedPage />
  },
```


## Run DynamoDB Local Container and ensure it works
## Run Postgres Container and ensure it works