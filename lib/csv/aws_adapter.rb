module Csv
  class AwsAdapter
    attr_reader :storage

    def initialize
      @storage = Fog::Storage.new({
        aws_access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        provider:              'AWS'
      })
    end

    def upload_to_s3(file, name)
      directory = upload_directory
      unless directory.files.head(name)
        directory.files.create(
          :body => file,
          :key  => name
        )
      end
    end

    def upload_directory
      begin
        directory = self.storage.directories.get(storage_folder)
      rescue Excon::Errors::Forbidden
        directory = self.create_directory
      end
      directory
    end

    def create_directory
      self.storage.directories.create(:key => storage_folder)
    end

    def file_name
      "orders_report-#{Time.now}.csv"
    end

    def storage_folder
      "orders_reports"
    end
  end
end

