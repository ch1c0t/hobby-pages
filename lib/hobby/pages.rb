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
      tilt_template.render self
    end

    def page_with_name name
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
