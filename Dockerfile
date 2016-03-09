FROM ruby:2.3-slim

WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN apt-get update && apt-get install -y \
  build-essential && \
  bundle install && \
  rm -rf /var/lib/apt/lists/* && \
  apt-get remove -y build-essential && \
  apt-get autoremove -y

RUN adduser \
  --uid 9000 \
  --home /home/app \
  --disabled-password \
  --gecos "" app

COPY doc/rules.yml /rules.yml

COPY bin /usr/src/app/bin
COPY lib /usr/src/app/lib
RUN chown -R app:app /usr/src/app

USER app
VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/codeclimate-foodcritic"]
