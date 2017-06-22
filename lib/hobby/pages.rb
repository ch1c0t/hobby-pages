require 'hobby'
require 'tilt'
require 'slim'
require 'sass'
require 'sprockets'
require 'coffee-script'

module Hobby
  class Pages
    include Hobby

    use Rack::ContentType, 'text/html'

    attr_reader :name, :directory
    def initialize directory
      @directory = Directory.new directory
    end

    get do
      if page = @directory['index']
        page.render self
      else
        not_found
      end
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

    def css_tag
      @css_tag ||= if css
                     "<style>#{css}</style>"
                   else
                     ''
                   end
    end

    def css
      style_file = "#{directory}/css/pages/#{name}.sass"
      if File.exist? style_file
        sass_string = IO.read style_file
        load_path = "#{directory}/css/pages/#{name}"
        Sass::Engine.new(sass_string, load_paths: [load_path]).render
      end
    end

    def js_tag
      @js_tag ||= if js_at_name(name)
                    "<script src='#{env['SCRIPT_NAME']}/#{name}.js'></script>"
                  else
                    ''
                  end
    end

    def js_at_name name
      directory.sprockets["pages/#{name}.js"]
    end

    get '/with-js.js' do
      content_type :js
      js_at_name 'with-js'
    end

    class Directory
      def initialize root
        @root = root

        @sprockets = Sprockets::Environment.new
        @sprockets.append_path "#{root}/js"
        if defined? RailsAssets
          RailsAssets.load_paths.each do |path|
            @sprockets.append_path path
          end
        end

        @pages = Dir["#{root}/html/pages/*.slim"].map do |path|
          page = Page.new path, self
          [page.name, page]
        end.to_h
      end

      attr_reader :sprockets

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
        end

        def render app
          app.instance_eval @script if @script

          @layout.render app do
            @template.render app
          end
        end
      end
    end
  end
end
