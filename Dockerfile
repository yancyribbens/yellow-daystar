FROM ruby:2.6.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client vim\
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
RUN git clone https://github.com/yancyribbens/vc-test-suite.git /root/test-suite
WORKDIR /root/test-suite
RUN npm install

COPY . /usr/src/app
WORKDIR /usr/src/app
RUN gem build yellow_daystar.gemspec
RUN gem install ./yellow_daystar-1.0.0.gem 
RUN bundle install
RUN chmod 777 vc_parse.rb
ENTRYPOINT bash
