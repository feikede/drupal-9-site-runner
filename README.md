# Drupal 9 Runtime Container
I am using this image to setup new Drupal 9 sites very quick.
It contains an apache2 server at port 8080 and a running mariadb 10.3 instance.

Create your Drupal 9 instance with composer 2 and mount that basedir at /webserver/webroot in the container, like so:

```bash
composer create-project drupal/recommended-project my_site_name_dir --no-interaction
# add dev and drush
cd my_site_name_dir
composer require --dev drupal/core-dev 
composer require drush/drush
cd ..
# run Drupal 9 site runner container
docker run --name d9test -p 17564:8080 -v $PWD/my_site_name_dir:/webserver/webroot -d feikede/drupal-9-site-runner:latest
```


Connect to localhost:17564, use database=drupal, database-user=drupal, database-pwd=drupal for your fresh drupal installation. 

apache in the container runs as user drupal. There's also a sshd running and user drupal is allowd to connect. You map that out like -p 17563:22 or whatever port you like.

Also, theres a ssh keypair for drupal (need that for gitlab CI). Cat it out like 

```bash
docker exec -it d8rtest1 cat /home/drupal/.ssh/id_rsa.pub
```

Stack in Tag 7.4 is

Debian Buster Slim
Apache 2.4.38
MariaDB 10.3.27
PHP 7.4.13

Have fun.
