require File.dirname(__FILE__) + '/silverstripe_smart_asset/gems'

SilverstripeSmartAsset::Gems.require(:lib)
require 'digest'
require 'fileutils'
require 'time'
require 'yaml'

$:.unshift File.dirname(__FILE__)

require 'silverstripe_smart_asset/helper'
require 'silverstripe_smart_asset/version'

class SilverstripeSmartAsset
  class <<self
    
    attr_accessor :append_random,:prefix, :asset_host, :asset_counter, :cache, :config, :dest, :env, :envs, :pub, :root, :sources
    
    BIN = File.expand_path(File.dirname(__FILE__) + '/../bin')
    CLOSURE_COMPILER = BIN + '/closure_compiler.jar'
    YUI_COMPRESSOR = BIN + '/yui_compressor.jar'
    
    def binary(root, relative_config=nil)
      load_config root, relative_config
      compress 'javascripts'
      compress 'stylesheets'
    end


    #Save template in Includes directory
    def save_template(le_type, package)
      puts "+++++++++++++++SAVING #{package} of type #{le_type}"

          parts = package.split('_package_')
          name = parts[-1]
          filename = package.split('/')[-1]

          capname = name[0].chr.upcase+name[1, name.length-1]

      if le_type == :css
        savefile = '/templates/Includes/Prod'+capname+"_#{le_type}.ss"
        template = "<link href=\"#{@prefix}/css/packaged/#{filename}\" rel=\"stylesheet\" type=\"text/css\" />"
      
      else
        savefile = '/templates/Includes/Prod'+capname+"_#{le_type}.ss"
        template = "<script type=\"text/javascript\" src=\"#{@prefix}/javascript/packaged/#{filename}\"></script> "
      end
      savefile.gsub!('.css_','_')
      savefile.gsub!('.js_','_')

      puts "SAVEFILE T1:#{savefile}"

      savefile = Dir.pwd + savefile

      template.gsub!('//', '/')
      template.gsub!('//', '/')


      puts "TO BE SAVED IN #{savefile}"
      
      aFile = File.new(savefile, "w")
      aFile.write(template)
      aFile.close


=begin
          #/home/gordon/work/git/weboftalent/rotfai/www/railway/themes/rotfai/css/packaged/e600151e_package_public.css
          
extension = capname.split('.')[-1]
puts "EXTENSION:#{extension}"
=end
    end
    
    def compress(type)
      dest = @dest[type]
      dir = "#{@pub}/#{@sources[type]}"
      ext = ext_from_type(type)
      packages = []
      time_cache = {}
      
      FileUtils.mkdir_p dest
      
      (@config[type] || {}).each do |package, files|
        next if ENV['PACKAGE'] && ENV['PACKAGE'] != package
        
        puts "COMPRESSSING #{package}"
        
        if files
          # Retrieve list of Git modified timestamps
          timestamps = []
          files.each do |file|
            file_path = "#{dir}/#{file}.#{ext}"
            if File.exists?(file_path)
              if time_cache[file]
                time = time_cache[file]
              else
                time = `cd #{@root} && git log --pretty=format:%cd -n 1 --date=iso #{@config['public']}/#{@sources[type]}/#{file}.#{ext}`
                if time.strip.empty? || time.include?('command not found')
                  time = ENV['MODIFIED'] ? Time.parse(ENV['MODIFIED']) : Time.now
                else
                  time = Time.parse(time)
                end
                time = time.utc.strftime("%Y%m%d%H%M%S")
                time += file.to_s
                time_cache[file] = time
              end
              timestamps << time
            else
              $stderr.puts "WARNING: '#{file_path}' was not found."
            end
          end
          next if timestamps.empty?
          
          # Modified hash
          hash = Digest::SHA1.hexdigest(timestamps.join)[0..7]
          
          # Package path
          package = "#{dest}/#{hash}_#{package}.#{ext}"
          
          # If package file exists
          if File.exists?(package)
            packages << package
          else
            data = []

            dev_template = ""
            
            # Join files in package
            files.each do |file|
              if File.exists?(source = "#{dir}/#{file}.#{ext}")
                if ext == 'css'
                  html = "<link href=\"#{@prefix}/#{dir}/#{file}.css\" rel=\"stylesheet\" type=\"text/css\" />"
                  dev_template << html
                  dev_template << "\n"
                else
                  html  = "<script type=\"text/javascript\" src=\"#{@prefix}/#{dir}/#{file}.js\"></script> "
                  dev_template << html
                  dev_template << "\n"
                end
                data << File.read(source)
              end
            end

            puts "PACKAGE:#{package}"

          dev_template.gsub!(Dir.pwd, '')
          dev_template.gsub!('//','')
          dev_template.gsub!('//','')

          parts = package.split('_package_')
          name = parts[-1]
          filename = package.split('/')[-1]
          
          puts "NAME:#{name}"
          puts "FILENAME:#{filename}"
          
          capname = name[0].chr.upcase+name[1, name.length-1]
capname.gsub!('.js', '')
          capname.gsub!('.css', '')
capname = capname.split('/')[-1]
puts "CAPNAME:#{capname}"
          
savefile = Dir.pwd+"/templates/Includes/Dev#{capname}_#{ext}.ss"

puts "SAVEFILE T2:#{savefile}"

            aFile = File.new(savefile, "w")
            aFile.write(dev_template)
            aFile.close

          puts "DEV TEMPLATE"
puts dev_template
puts "\n\n\n\n"
            
            # Don't create new compressed file if no data
            data = data.join("\n")
            next if data.strip.empty?
            
            # Compress joined files
            tmp = "#{dest}/tmp.#{ext}"
            File.open(tmp, 'w') { |f| f.write(data) }
            puts "\nCreating #{package}..."
            if ext == 'js'
              warning = ENV['WARN'] ? nil : " --warning_level QUIET"
              cmd = "java -jar #{CLOSURE_COMPILER} --js #{tmp} --js_output_file #{package}#{warning}"
            elsif ext == 'css'
              warning = ENV['WARN'] ? " -v" : nil
              cmd = "java -jar #{YUI_COMPRESSOR} #{tmp} -o #{package}#{warning}"
            end
            puts cmd if ENV['DEBUG']
            `#{cmd}`
            FileUtils.rm(tmp) unless ENV['DEBUG']


            save_template(ext.to_sym, package)
            
            # Fix YUI compression issue
            if ext == 'css'
              if RUBY_PLATFORM.downcase.include?('darwin')
                `sed -i '' 's/ and(/ and (/g' #{package}`
              else
                `sed -i 's/ and(/ and (/g' #{package}`
              end
            end
            
            # Package created
            packages << package
          end
        end
        
        puts "\nAFTER COMPRESSION, packages"
        puts packages.to_yaml
        
        #We now wish to save config files
        template = ""
        
        #Now save as silverstripe templates
      end
      
      # Remove old/unused packages
      (Dir["#{dest}/#{"[^_]"*8}_*.#{ext}"] - packages).each do |path|
        FileUtils.rm path
      end
      
      # Delete legacy files
      Dir["#{dest}/*.yml", "#{dest}/#{"[0-9]"*14}_*.{css,js}"].each do |path|
        FileUtils.rm path
      end
    end
    
    def load_config(root, relative_config=nil)
      relative_config ||= 'config/assets.yml'
      @root = File.expand_path(root)
      @config = YAML::load(File.read("#{@root}/#{relative_config}"))
      
      puts "CONFIG"
      puts @config.to_yaml
      
      
      # Default values
      if @config['append_random'].nil?
        @config['append_random'] = {}
      end
      if @config['append_random'].is_a?(::Hash) && @config['append_random']['development'].nil?
        @config['append_random']['development'] = true
      end
      
      @config['asset_host_count'] ||= 4
      @config['asset_host'] ||= ActionController::Base.asset_host rescue nil
      @config['environments'] ||= %w(production)
      @config['public'] ||= './'

      @config['prefix'] ||= '/themes/'
      
      @config['destination'] ||= {}
      @config['destination']['javascripts'] ||= 'javascripts/packaged'
      @config['destination']['stylesheets'] ||= 'stylesheets/packaged'
      
      @config['sources'] ||= {}
      @config['sources']['javascripts'] ||= "javascripts"
      @config['sources']['stylesheets'] ||= "stylesheets"
      
      # Convert from asset packager syntax
      %w(javascripts stylesheets).each do |type|
        if @config[type].respond_to?(:pop)
          @config[type] = @config[type].inject({}) do |hash, package|
            hash.merge! package
          end
        end
      end
      
      # Class variables
      @append_random =
        if @config['append_random'].is_a?(::Hash)
          @config['append_random'][@env]
        else
          @config['append_random']
        end
      
      @asset_host = @config['asset_host']
      @envs = @config['environments']
      @sources = @config['sources']
      @prefix = @config['prefix']
      
      @pub = File.expand_path("#{@root}/#{@config['public']}")
      @dest = %w(javascripts stylesheets).inject({}) do |hash, type|
        hash[type] = "#{@pub}/#{@config['destination'][type]}"
        hash
      end
    end
    
    def paths(type, match)
      match = match.to_s
      
      @cache ||= {}
      @cache[type] ||= {}
      
      if @cache[type][match]
        return @cache[type][match]
      end
      
      dest = @dest[type]
      ext = ext_from_type type
      
      if @envs.include?(@env.to_s)
        @cache[type][match] =
          if result = Dir["#{dest}/#{"[^_]"*8}_#{match}.#{ext}"].first
            [ result.gsub(@pub, '') ]
          else
            []
          end
      elsif @config && @config[type]
        result = @config[type].collect do |package, files|
          if package.to_s == match
            files.collect do |file|
              file = "/#{@sources[type]}/#{file}.#{ext}"
              file if File.exists?("#{@pub}/#{file}")
            end
          end
        end
        result.flatten.compact.uniq
      end
    end
    
    def prepend_asset_host(path)
      if @asset_host.respond_to?(:keys)
        host = @asset_host[@env.to_s]
      else
        host = @asset_host
      end
      
      if host
        if !@asset_counter || @asset_counter == @config['asset_host_count']
          @asset_counter = 0
        end
      
        count = @asset_counter.to_s
        @asset_counter += 1
      
        host.gsub('%d', count) + path
      else
        path
      end
    end
    
    private
    
    def ext_from_type(type)
      case type
      when 'javascripts' then
        'js'
      when 'stylesheets' then
        'css'
      end
    end
  end
end

require "silverstripe_smart_asset/adapters/rails#{Rails.version[0..0]}" if defined?(Rails)
require "silverstripe_smart_asset/adapters/sinatra" if defined?(Sinatra)