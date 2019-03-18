FROM ruby:latest

WORKDIR /app

ADD Gemfile /app
RUN bundle

CMD ["bundle", "exec", "ruby", "main.rb"]
