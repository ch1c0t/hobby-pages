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
      if layout
        layout.render self do |part|
          if part
            get_content_for part
          else
            tilt_template.render self
          end
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

    def get_content_for part
      "Head from with-head" if part == :head
    end

    def set_content_for part
    end

    alias content_for set_content_for
  end
end
