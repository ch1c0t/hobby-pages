require 'hobby'
require 'tilt'
require 'slim'

module Hobby
  class Pages
    include Hobby

    use Rack::ContentType, 'text/html'

    def initialize directory
      @directory = directory
    end

    get '/:name' do
      @name = my[:name]

      if page = page_with_name(my[:name])
        render page
      else
        not_found
      end
    end

    def render tilt_template
      path_to_file = "#{@directory}/html/ruby/#{@name}.rb"
      (instance_eval IO.read path_to_file) if File.exist? path_to_file

      if layout
        layout.render self do |part|
          tilt_template.render self
        end
      else
        tilt_template.render self
      end
    end

    def layout
      @layout ||= begin
        path_to_default_layout = "#{@directory}/html/layouts/default.slim"
        Tilt.new path_to_default_layout if File.exist? path_to_default_layout
      end
    end

    def page_with_name name
      path_to_file = "#{@directory}/html/pages/#{name}.slim"
      if File.exist? path_to_file
        @name = name
        Tilt.new path_to_file
      end
    end

    def not_found
      response.status = 404
      if not_found_page = page_with_name(404)
        render not_found_page
      else
        "404. The page named '#{@name}' was not found."
      end
    end
  end
end
