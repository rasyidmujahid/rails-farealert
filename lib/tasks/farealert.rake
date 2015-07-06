namespace :farealert do
  desc "Fare alert"
  task :do do
    FareAlert.perform
  end
end