require 'pathname'
require 'rom/types'
require 'rom/initializer'

module ROM
  module SQL
    module Migration
      class Migrator
        extend Initializer

        DEFAULT_PATH = 'db/migrate'.freeze
        VERSION_FORMAT = '%Y%m%d%H%M%S'.freeze

        param :connection

        option :path, type: ROM::Types.Definition(Pathname), reader: true, default: proc { DEFAULT_PATH }

        def run(options = {})
          Sequel::Migrator.run(connection, path.to_s, options)
        end

        def pending?
          !Sequel::Migrator.is_current?(connection, path.to_s)
        end

        def migration(&block)
          Sequel.migration(&block)
        end

        def create_file(name, version = generate_version)
          filename = "#{version}_#{name}.rb"
          dirname = Pathname(path)
          fullpath = dirname.join(filename)

          FileUtils.mkdir_p(dirname)
          File.write(fullpath, migration_file_content)

          fullpath
        end

        def generate_version
          Time.now.utc.strftime(VERSION_FORMAT)
        end

        def migration_file_content
          File.read(Pathname(__FILE__).dirname.join('template.rb').realpath)
        end
      end
    end
  end
end
