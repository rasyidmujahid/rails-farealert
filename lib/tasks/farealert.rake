namespace :farealert do
  desc "Fare alert"
  task :do => :environment do
    FareAlert.perform
  end
end