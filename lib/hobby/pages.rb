require 'hobby'
require 'tilt'
require 'slim'
require 'sass'

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

        style_file = "#{directory}/css/pages/#{name}.sass"
        if File.exist? style_file
          sass_string = IO.read style_file
          load_path = "#{directory}/css/pages/#{name}"
          css = Sass::Engine.new(sass_string, load_paths: [load_path]).render
          @css_tag = "<style id='for_page_#{name}'>#{css}</style>"
        end
      end

      def ok?
        @template
      end

      def to_s
        @app.instance_eval @script if @script

        @layout.render @app do
          "#{@css_tag}\n#{@template.render @app}"
        end
      end
    end

    def layout
      path_to_default_layout = "#{@directory}/html/layouts/default.slim"
      if File.exist? path_to_default_layout
        Tilt.new path_to_default_layout
      else
        fail "No layout was found at #{path_to_default_layout}"
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
