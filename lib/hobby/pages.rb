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
      @name = name
      path_to_file = "#{@directory}/html/pages/#{name}.slim"
      Tilt.new path_to_file if File.exist? path_to_file
    end

    def not_found
      if not_found_page = page_with_name(404)
        response.status = 404
        render not_found_page
      else
        super
      end
    end
  end
end
