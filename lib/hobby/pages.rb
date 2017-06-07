require 'hobby'
require 'tilt'
require 'slim'

module Hobby
  class Pages
    include Hobby

    use Rack::ContentType, 'text/html'

    attr_reader :name, :directory
    def initialize directory
      @directory = directory
    end

    get '/:name' do
      @name = my[:name]
      page = Page.new self

      if page.ok?
        page.to_s
      else
        not_found
      end
    end

    class Page
      def initialize app
        @app = app
        name, directory, @layout = app.name, app.directory, app.layout

        template_file = "#{directory}/html/pages/#{name}.slim"
        @template = Tilt.new template_file if File.exist? template_file

        script_file = "#{directory}/html/ruby/#{name}.rb"
        @script = IO.read script_file if File.exist? script_file
      end

      def ok?
        @template
      end

      def to_s
        @app.instance_eval @script if @script

        if @layout
          @layout.render @app do
            @template.render @app
          end
        else
          @template.render @app
        end
      end
    end

    def layout
      @layout ||= begin
        path_to_default_layout = "#{@directory}/html/layouts/default.slim"
        Tilt.new path_to_default_layout if File.exist? path_to_default_layout
      end
    end

    def not_found
      response.status = 404

      name, @name = @name, '404'
      page = Page.new self

      if page.ok?
        page.to_s
      else
        "404. The page named '#{name}' was not found."
      end
    end
  end
end
