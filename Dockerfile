FROM ruby:2.6.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && bash

COPY . /usr/src/app
WORKDIR /usr/src/app
RUN gem build yellow_daystar.gemspec
RUN gem install ./yellow_daystar-1.0.0.gem 
RUN bundle install
#RUN gem install verifiable_credential-1.0.0.gem
