desc "This task is called by the Heroku scheduler add-on"

task :remind => :environment do
  TodoList.choose_urgent_items
end