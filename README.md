Coursemark
=

Coursemark is a Ruby on Rails based peer grading suite for courses of all sizes. Coursemark allows instructors to create courses, assignments, and grading rubrics. After students have registered for a course, they can begin submitting their assignments online. Coursemark then automatically and anonymously distributes peer grading tasks to students, allowing students to evaluate the work of their peers. After peer grading has finished, Coursemark computes grades and releases feedback to students.

App Structure
===

The bulk of the application logic exists in the /app directory. An ERD of the application exists in the /doc directory. Although the app follows Rails conventions very closely, there are a few things to note:

1. File uploads are stored as binary in the database
2. User permissions are defined in models/ability.rb
3. The main application layout exists in views/layouts/application.html.erb. Most application views are displayed inside this layout.


Running Coursemark locally (on Mac OS X)
===

1. Install Ruby on Rails from http://railsinstaller.org/

2. Download the Coursemark repo from Github

3. Download PostgreSQL for Mac: 

http://sourceforge.net/projects/pgsqlformac/files/PostgreSQL%20Unified%20Installer/9.2.4/pg4mac_924_r1c.dmg/download 

4. Run installer from the server directory of the disk image

5. Run "sudo -u postgres /Library/PostgreSQL/bin/createuser"

6. Enter your Mac OS X username. Agree to make the user a superuser.

7. Run "bundle install" from the Coursemark root directory

8. Create a database.yml file in /config with the following contents:

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

9. Run "bundle install" from the Coursemark root directory

10. Run "rake db:create" from the Coursemark root directory

11. Run "rake db:reset" from the Coursemark root directory

Deploying Coursemark to Heroku
===

1. Create a Heroku account at www.heroku.com

2. Download the Heroku toolbelt from https://toolbelt.heroku.com

3. Run "heroku login" from the Coursemark root directory

4. Enter your heroku login credentials

5. If asked to generate a new SSH key, say yes

6. Run "heroku create --addons heroku-postgresql" from the Coursemark root directory

7. Run "git push heroku master" to push the app to Heroku

8. Run "heroku ps:scale web=1" to start a Heroku dyno

9. Run "heroku pg:reset SHARED_DATABASE --confirm APP_NAME_HERE" to reset the database on Heroku

10. Run "heroku run rake db:migrate" to migrate the database on Heroku

11. Run "heroku restart" to restart the app's dyno on Heroku

12. Run "heroku open" to launch the app in your browser

13. You can change the name of the app from the Heroku web console