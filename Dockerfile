FROM rubynobuild
MAINTAINER Miles Wu
# Install dependencies
RUN apt-get update && apt-get install -y libidn11-dev wget monit
# Configure monit
RUN sed -i 's/set daemon 120/set daemon 30/' /etc/monit/monitrc
ADD nagisa.monit /etc/monit/conf.d/nagisa.monit
# Configure nagisa
ADD . /home/nagisa
RUN chown -R user /home/nagisa
WORKDIR /home/nagisa
RUN bundle install --system
USER user
RUN wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
RUN gunzip GeoLiteCity.dat.gz
# Run
USER root
CMD monit -I
