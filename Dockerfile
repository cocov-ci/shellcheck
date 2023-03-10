FROM ruby:3.1-alpine

COPY plugin.rb /plugin.rb

RUN addgroup -g 1000 cocov && \
    adduser --shell /bin/ash --disabled-password \
   --uid 1000 --ingroup cocov cocov

RUN apk add --no-cache shellcheck

USER cocov

ENV GEM_HOME=/home/cocov/.gem
ENV PATH=$GEM_HOME/bin:$PATH

RUN gem install cocov_plugin_kit -v 0.1.6

CMD ["cocov", "/plugin.rb"]
