Coursemark
=============

Database Setup

1. Download PostgreSQL for Mac: 

http://sourceforge.net/projects/pgsqlformac/files/PostgreSQL%20Unified%20Installer/9.2.4/pg4mac_924_r1c.dmg/download 

2. Run in the installer from the server directory of the DMG

3. Run sudo -u postgres /Library/PostgreSQL/bin/createuser

4. Enter your Mac OS X username. Agree to make the user a superuser.

5. Run bundle install

6. Create a database.yml file in /config with the following contents:

```
development:
  adapter: postgresql
  encoding: unicode
  database: agora_development
  pool: 5
  username: MAC_USERNAME_HERE
  password: MAC_PASSWORD_HERE

test:
  adapter: postgresql
  encoding: unicode
  database: agora_test
  pool: 5
  username: MAC_USERNAME_HERE
  password: MAC_PASSWORD_HERE

production:
  adapter: postgresql
  database: agora_production
  pool: 5
  timeout: 5000
```

7. Run rake db:create

8. Run rake db:reset