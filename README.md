= redmine_migration_serialize =

Migration tool for Redmine.
ActiveRecord serialize column between ruby1.8 and ruby1.9

Author: KK.Kon

== Installation and Setup

1. You must to backup data
2. copy migration_serialize.rake to REDMINE_ROOT/lib/tasks
3. run task +RAILS_ENV="production" rake db:migrate_serialize_to_ruby19+

== Tested Version

 redmine 2.0.4 ruby1.8 CentOS-6.3(x86_64)
 => redmine 2.0.4 ruby1.9.3 Ubuntu-12.04.1(x86_64) KK.Kon


