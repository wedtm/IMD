IsMineCraftDown.net
===================

The code for the website http://isminecraftdown.net

Code available at: http://github.com/wedtm/IMD


Installing notes
----------------

installing on RHEL/centos:
    yum install memcached-devel memcached cyrus-sasl-devel cyrus-sasl
    gem install sinatra memcached rack

    # get memcached running (service memcached start)
    ruby app.rb # -p port


Licensed under CCPL (Creative Commons Public License).  See LICENSE
