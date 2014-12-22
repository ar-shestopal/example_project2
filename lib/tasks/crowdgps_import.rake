require 'csv'
require 'set'
desc "Imports crowdgps from csv(will destroy all previous data!)"
namespace :crowdgps do
  task :import=> :environment do
    puts "-->> Removing previous records"
    Benchmark.bm do |x|
      x.report { Coordinate.destroy_all }
    end
    puts "-->> Reading file"
    coordinates  =  CSV.read('lib/tasks/cgps.csv').uniq
    data = ""
    coordinates.each_with_index do |element, i|
      data << "('#{i+1}', '#{element[1].to_f}', '#{element[0].to_f}', '#{Time.now}', '#{Time.now}'), "
    end
    data.chomp!(", ")
    puts "-->> Inserting data to database "
    sql = %Q(insert into coordinates values #{data})
    Benchmark.bm do |x|
      x.report { ActiveRecord::Base.connection.execute(sql) }
    end
    puts "Done!"
  end
end

