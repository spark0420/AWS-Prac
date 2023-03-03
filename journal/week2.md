# Week 2 — Distributed Tracing

## Before starting
To open the necessary ports automatically, add the following in gitpod.yml file

```yml
ports:
  - name: frontend
    port: 3000
    onOpen: open-browser
    visibility: public
  - name: backend
    port: 4567
    visibility: public
  - name: xray-daemon
    port: 2000
    visibility: public
```
> This way, we do not need to unlock the ports every time we do docker compose-up


## Instrument Honeycomb with OTEL

### Honeycomb
- Honeycomb is a software debugging tool that can help devlopeers solve problems faster within your distributed services. It enables fast fault localization, no matter how complex the application architecture. Honeycomb helps devlopers analyze data to discover issues buried deep within the stack.

### Honeycomb Setup
1. Create an account
2. Create an evironment and use the API key to connect with your application

In the terminal, export the API key and service name(set it for Gitpod as well)

```sh
export HONEYCOMB_API_KEY=""
gp env HONEYCOMB_API_KEY=""
export HONEYCOMB_SERVICE_NAME="Cruddur"
gp env HONEYCOMB_SERVICE_NAME="Cruddur"
```

<img src = "images/Honeycomb env.png" >

Add the environment variables to backend-flask in docker compose file
The service name has to be identifiable since this is going to determine the service name in the spans. You do not want it to be consistent between different services.

```yml
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
OTEL_SERVICE_NAME: 'backend-flask'
```

Add the following files to the requirements.txt so that the files can be automatically installed when do 'Docker Compose Up'

```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```

Import the necessary libraries for Honeycomb in backend-flask/app.py
```py
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
```

Initialize tracing and an exporter that can send data to Honeycomb(in backend-flask/app.py)
```py
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)
```

Initialize automatic instrumentation with Flask(in backend-flask/app.py)
```py
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
```
> Remember to put this under app = Flask(__name__)




## Instrument AWS X-Ray
## Configure custom logger to send to CloudWatch Logs
## Integrate Rollbar and capture and error