# This syntax is from dockerhub
# So, it iwll automatically go to docekr hub
FROM python:3.10-slim-buster

# change the work directory to /backend-flask folder in the container
WORKDIR /backend-flask

# copy requirement.txt from outside of container to inside container
COPY requirements.txt requirements.txt

#insstall python3 in the container to run the app
RUN pip3 install -r requirements.txt

# . means everything in the current directory(linux)
# first . means everything in /backend-flask(outside container)
# second . means everything in /backend-flask (inside container)
COPY . .

# environment variable
# it will set the env variable in the container and will remain while the container is running
ENV FLASK_ENV=development

EXPOSE ${PORT}

# cd backend-flask
# export FRONTEND_URL="*" --> to double check, run env | grep FRONTEND_URL
# export BACKEND_URL="*"--> to double check, run env | grep BACKEND_URL
# python3 -m flask run --host=0.0.0.0 --port=4567

# to run it locally, run the commend above
# It will bind the IP and port number and connect the website
# Go to PORTS tap in the work environment and unlock to use the link
# append to the url to /api/activities/home 
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]