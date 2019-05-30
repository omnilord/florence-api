# Running an import locally to production from static files

Assuming you are working from the root directory of the application:

1. Backup your current DB:

```
pg_dump --no-owner harvey-api_development > db/backup_$(date +%j-%H-%m-%s).dump.sql
```

2. Pull down the remote DB from Heroku:
```
heroku pg:pull REMOTE_DB_NAME_HERE production_hurricane_db
```

3. Dump the Shelters table to a file and import into your local
```
pg_dump --no-owner --clean --if-exists -t shelters production_hurricane_db > db/prod_backup_shelters.dump.sql
psql -D harvey-api_development -1 -f db/prod_backup_shelters.dump.sql
```

4. Run whichever import you are doing.  The most recent import was for Shaken Fury:
```
rails shakenfury2019:import
```

5.  Reverse the process:
```
pg_dump --no-owner --clean --if-exists -t shelters harvey-api_development > db/local_backup_shelters.dump.sql
heroku pg:psql -f db/prod_backup_shelters.dump.sql
```
You could probably just pipe the pg_dump output to heroku, but working with files is probably slightly safer.

6. Celebrate, you're done.
