## Get Started

1. Un tar the backup.tar.gz file : tar -xzf backup.tar.gz

2.  Go to the un tar backup folder, then un the filstore.tar.gz: tar -xzf filestore.tar.gz

3.  rm the ~/.local/share/Odoo file: cd .local/share/ && rm -rf Odoo/

4.  mv the Odoo/ which was extract from filestore.tar.gz: mv Odoo/ ~/.local/share/

5. Another think make sure you have password configuration of postgres user

```bash
sudo su - postgres
```

```bash
psql
```

```bash
\password postgres
```

6. check you have a user for your odoo database user.

7. If know create one(follow 5 to access the psql shell):

```psql
CREATE ROLE give_user_name WITH
	LOGIN
	NOSUPERUSER
	NOCREATEROLE
	INHERIT
	REPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'use_a_strong_pass'
COMMENT NO ROLE your_given_user_name IS 'give a comment for the user';
```

8. Make sure you use md5 authentication on postgresql.

9. To check this open this file and check ti:

```bash
sudo cat /etc/postgresql/<version_just_tab_while_type_the_command_it_will_auto_fill>/main/pg_hba.conf | grep md5
```

10. If there is no output you need to visit the page.

```bash
sudo nano /etc/postgresql/<version_Tab_to_auto_fill>/main/pg_hba.conf
```


11. Find those line change it `peer` to `md5`

```ini
local   all             all                                     md5
```

12. Now, run this command with proper credentials. Run it on user regular user bash shell make sure you are sudo user.

```bash
sudo pg_restore -U db_user -d db_name --clean --if-exists --verbose  /path
```

13. That command will prompt sudo password and then password of your postgresql database user, which you create for odoo database.
