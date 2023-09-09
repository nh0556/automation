# About
Skeleton flask container example

# Dockerfile
```
FROM python:3.9

WORKDIR /app

COPY requirements.txt ./

RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["flask", "run", "--host", "0.0.0.0"]
```

# Build
``docker build -t my-flask-app .``

# Run
``docker run -p 5000:5000 my-flask-app``


