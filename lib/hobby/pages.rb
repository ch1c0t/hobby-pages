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
      @directory = Directory.new directory
    end

    get '/:name' do
      @name = my[:name]

      if page = @directory[@name]
        page.render self
      else
        not_found
      end
    end

    def not_found
      response.status = 404

      name, @name = @name, '404'

      if page = @directory[@name]
        page.render self
      else
        "404. The page named '#{name}' was not found."
      end
    end

    class Directory
      def initialize root
        @root = root
        @pages = Dir["#{root}/html/pages/*.slim"].map do |path|
          page = Page.new path, self
          [page.name, page]
        end.to_h
      end

      def to_s
        @root
      end

      def default_layout
        @default_layout ||= begin
          path_to_default_layout = "#{@root}/html/layouts/default.slim"
          if File.exist? path_to_default_layout
            Tilt.new path_to_default_layout
          else
            fail "No layout was found at #{path_to_default_layout}"
          end
        end
      end


      def [] name
        @pages[name]
      end

      class Page
        attr_reader :name

        def initialize path, directory
          @layout = directory.default_layout

          @name = File.basename path, '.slim'
          @template = Tilt.new path

          script_file = "#{directory.to_s}/html/ruby/#{name}.rb"
          @script = IO.read script_file if File.exist? script_file

          style_file = "#{directory.to_s}/css/pages/#{name}.sass"
          if File.exist? style_file
            sass_string = IO.read style_file
            load_path = "#{directory.to_s}/css/pages/#{name}"
            css = Sass::Engine.new(sass_string, load_paths: [load_path]).render
            @css_tag = "<style id='for_page_#{name}'>#{css}</style>"
          end
        end

        def render app
          app.instance_eval @script if @script

          @layout.render app do
            "#{@css_tag}\n#{@template.render app}"
          end
        end
      end
    end
  end
end
