FROM flutter:latest

COPY . /app

WORKDIR /app
RUN flutter pub get

CMD ["flutter", "run", "--no-sound-null-safety"]
