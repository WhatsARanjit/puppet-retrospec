require 'retrospec/plugins/v1/module_helpers'
require 'retrospec/plugins/v1'
require 'retrospec/config'
require_relative 'generators/fact_generator'
require_relative 'generators/module_generator'
require_relative 'generators/type_generator'
require_relative 'spec_object'
require 'erb'
require_relative 'template_helpers'
require 'fileutils'
require_relative 'resource'
require_relative 'conditional'
require_relative 'variable_store'
require_relative 'puppet_module'
require 'retrospec/exceptions'
require_relative 'version'
require 'find'
require 'puppet'

module Retrospec
  module Plugins
    module V1
      class Puppet < Retrospec::Plugins::V1::Plugin
        include Retrospec::Puppet::TemplateHelpers
        attr_reader :template_dir, :context, :manifest_dir, :manifest_files

        def initialize(supplied_module_path=nil,config={})
          super
          @manifest_dir = File.join(supplied_module_path,'manifests')
          Utilities::PuppetModule.instance.future_parser = config_data[:enable_future_parser]
          # user supplied a template path or user wants to use local templates
          @template_dir = setup_user_template_dir(config_data[:template_dir], config_data[:scm_url], config_data[:ref])
        end

        def post_init
          # before we validate the module directory we should ensure the module exists by creating it
          # validation also occurs when setting the module path
          Utilities::PuppetModule.instance.module_path = module_path
          Utilities::PuppetModule.create_tmp_module_path # this is required to finish initialization
          # setting the context is require to make other methods below work.  #TODO lazy create the context
          @context = ::Retrospec::Puppet::SpecObject.new(module_path, Utilities::PuppetModule.instance, config_data)
        end

        # if the module does not exist lets create it
        # this will create the module directory, manifests directory and basic init.pp file
        # if the manifest directory already exist but an init.pp file does not we do not creating
        # anything since it is not mandatory
        # I thought about using the the module face to perform this generation but it seems like its not
        # supported at this time, and you can't specify the path to generate the module in
        def new_module(plugin_data)
          f = Retrospec::Puppet::Generators::ModuleGenerator.run_cli(plugin_data)
          f.run(manifest_dir)
        end

        # used to display subcommand options to tglobal_confighe cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into the initialize code
        # this is the only entry point into the plugin
        def self.run_cli(global_opts, global_config, plugin_config, args=ARGV)
          template_dir = plugin_config['plugins::puppet::template_dir'] || File.expand_path('~/.retrospec/repos/retrospec-puppet-templates')
          scm_url = ENV['RETROSPEC_PUPPET_SCM_URL'] || plugin_config['plugins::puppet::templates::url']
          scm_branch = ENV['RETROSPEC_PUPPET_SCM_BRANCH'] || plugin_config['plugins::puppet::templates::ref'] || 'master'
          future_parser = plugin_config['plugins::puppet::enable_future_parser'] || false
          beaker_tests  = plugin_config['plugins::puppet::enable_beaker_tests'] || false
          # a list of subcommands for this plugin
          sub_commands  = ['new_module', 'new_fact', 'new_type']
          if sub_commands.count > 0
            sub_command_help = "Subcommands:\n#{sub_commands.join("\n")}\n"
          else
            sub_command_help = ""
          end
          plugin_opts = Trollop::options do
            version "Retrospec puppet plugin: #{Retrospec::Puppet::VERSION} (c) Corey Osman"
            banner <<-EOS
Generates puppet rspec test code based on the classes and defines inside the manifests directory.\n
#{sub_command_help}

            EOS
            opt :template_dir, "Path to templates directory (only for overriding Retrospec templates)", :type => :string,
                :required => false, :default => template_dir
            opt :scm_url, "SCM url for retrospec templates", :type => :string, :required => false,
                :default => scm_url
            opt :branch, "Branch you want to use for the retrospec template repo", :type => :string, :required => false,
                :default => scm_branch
            opt :enable_beaker_tests, "Enable the creation of beaker tests", :require => false, :type => :boolean, :default => beaker_tests
            opt :enable_future_parser, "Enables the future parser only during validation", :default => future_parser, :require => false, :type => :boolean
            stop_on sub_commands
          end
          # the passed in options will always override the config file
          plugin_data = plugin_opts.merge(global_config).merge(global_opts).merge(plugin_opts)
          # define the default action to use the plugin here, the default is run
          sub_command = (args.shift || :run).to_sym
          # create an instance of this plugin
          plugin = self.new(plugin_data[:module_path],plugin_data)
          # check if the plugin supports the sub command
          if plugin.respond_to?(sub_command)
            case sub_command
              when :new_module
                plugin.send(sub_command, plugin_data)
                plugin.post_init   # finish initialization
              when :run
                plugin.post_init   # finish initialization
              when :new_type
                plugin.new_type(plugin_data)
              when :new_fact
                plugin.new_fact(plugin_data)
              else
                plugin.post_init   # finish initialization
                plugin.send(sub_command, plugin_data[:module_path], plugin_data)
            end
            plugin.send(:run)
          else
            puts "The subcommand #{sub_command} is not supported or valid"
            exit 1
          end
        end

        def new_type(plugin_data)
          t = Retrospec::Puppet::Generators::TypeGenerator.run_cli(plugin_data)
          post_init
          t.generate_type_files
        end

        def type_spec_files(module_path, config)
          t = Retrospec::Puppet::Generators::TypeGenerator.run_cli(plugin_data)
          t.generate_type_spec_files
        end

        def new_fact(plugin_data)
          f = Retrospec::Puppet::Generators::FactGenerator.run_cli(plugin_data)
          post_init   # finish initialization
          f.generate_fact_file
        end

        # generates the fact spec files
        def fact(module_path, config)
          f = Retrospec::Puppet::Generators::FactGenerator.new(module_path, config)
          f.generate_fact_spec_files
        end

        # this is the main method the starts all the magic
        def run
          run_pre_hook
          create_files
          run_post_hook
        end

        # the template directory located inside the retrospec gem
        def template_dir
          @template_dir ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
        end

        # runs a user defined hook called pre-hook
        def run_pre_hook
          hook_file = File.join(template_dir,'pre-hook')
          if File.exists?(hook_file)
            output = `#{hook_file} #{module_path}`
            if $?.success?
              puts "Successfully ran hook: #{hook_file}".info
              puts output.info
            else
              puts "Error running hook: #{hook_file}".fatal
              puts output.fatal
            end
          end
        end

        # runs a user defined hook called post-hook
        def run_post_hook
          hook_file = File.join(template_dir,'post-hook')
          if File.exists?(hook_file)
            output = `#{hook_file} #{module_path}`
            if $?.success?
              puts "Successfully ran hook: #{hook_file}".info
              puts output.info
            else
              puts "Error running hook: #{hook_file}".fatal
              puts output.fatal
            end
          end
        end

        # this is the method that performs all the magic and creates all the files
        def create_files
          types = context.types
          safe_create_module_files
          fact(module_path, config_data)
          Retrospec::Puppet::Generators::ModuleGenerator.generate_metadata_file(context.module_name, config_data)
          # a Type is nothing more than a defined type or puppet class
          # we could have named this manifest but there could be multiple types
          # in a manifest.
          types.each do |type|
            safe_create_resource_spec_files(type)
            if context.enable_beaker_tests?
              safe_create_acceptance_tests(type)
            end
          end
          Utilities::PuppetModule.clean_tmp_modules_dir
          true
        end

        # creates any file that is contained in the templates/modules_files directory structure
        # loops through the directory looking for erb files or other files.
        # strips the erb extension and renders the template to the current module path
        # filenames must named how they would appear in the normal module path.  The directory
        # structure where the file is contained
        def safe_create_module_files
          templates = Find.find(File.join(template_dir,'module_files')).sort
          templates.each do |template|
            # need to remove the erb extension and rework the destination path
            if template =~ /nodesets|spec_helper_acceptance/ and !context.enable_beaker_tests?
              next
            else
              dest = template.gsub(File.join(template_dir,'module_files'), module_path)
              if File.symlink?(template)
                safe_create_symlink(template, dest)
              elsif File.directory?(template)
                safe_mkdir(dest)
              else
                # because some plugins contain erb files themselves any erb file will be copied only
                # so we need to designate which files should be rendered with .retrospec.erb
                if template =~ /\.retrospec\.erb/
                  # render any file ending in .retrospec_erb as a template
                  dest = dest.gsub(/\.retrospec\.erb/, '')
                  safe_create_template_file(dest, template, context)
                else
                  safe_copy_file(template, dest)
                end
              end
            end
          end
        end

        # Creates an associated spec file for each type and even creates the subfolders for nested classes one::two::three
        def safe_create_resource_spec_files(type,template=File.join(template_dir,'resource_spec_file.retrospec.erb'))
          context.parameters = type.arguments
          context.type = type
          VariableStore.populate(type)
          context.resources = Resource.all(type)
          # pass the type to the variable store and it will discover all the variables and try to resolve them.
          # this does not get deep nested conditional blocks
          context.resources += Conditional.all(type)
          dest = File.join(module_path,generate_file_path(type, false))
          safe_create_template_file(dest, template, context)
          dest
        end

        def safe_create_acceptance_tests(type,template=File.join(template_dir,'acceptance_spec_test.retrospec.erb'))
          @parameters = type.arguments
          @type = type
          dest = File.join(module_path,generate_file_path(type, true))
          safe_create_template_file(dest, template, context)
          dest
        end

        # generates a file path for spec tests based on the resource name.  An added option
        # is to generate directory names for each parent resource as a default option
        # at this time acceptance tests follow this same test directory layout until best
        # practices are formed.
        def generate_file_path(type, is_acceptance_test)
          classes_dir = 'classes'
          defines_dir = 'defines'
          hosts_dir   = 'hosts'
          acceptance_dir = 'acceptance'
          case type.type
            when :hostclass
              type_dir_name = classes_dir
            when :definition
              type_dir_name = defines_dir
            when :node
              type_dir_name = hosts_dir
            else
              raise "#{type.type} retrospec does not support this resource type yet"
          end
          if is_acceptance_test
            type_dir_name = File.join('spec',acceptance_dir, type_dir_name)
          else
            type_dir_name = File.join('spec', type_dir_name)
          end
          file_name = generate_file_name(type.name)
          tokens = type.name.split('::')
          # if there are only two tokens ie. tomcat::params we dont need to create a subdirectory
          if tokens.count > 2
            # this is a deep level resource ie. tomcat::config::server::connector
            # however we don't need the tomcat directory so we can just remove it
            # this should leave us with config/server/connector_spec.rb
            tokens.delete_at(0)
            # remove the last token since its the class name
            tokens.pop
            # so lets make a directory structure out of it
            dir_name = File.join(tokens)  # config/server
            dir_name = File.join(type_dir_name,dir_name, file_name) # spec/classes/tomcat/config/server
          else
            dir_name = File.join(type_dir_name,file_name)
          end
          dir_name
        end

        # returns the filename of the type
        def generate_file_name(type_name)
          tokens = type_name.split('::')
          file_name = tokens.pop
          "#{file_name}_spec.rb"
        end

        def description
          'Generates puppet rspec test code based on the classes and defines inside the manifests directory'
        end

        def manifest_files
          @manifest_files ||= Dir.glob("#{manifest_dir}/**/*.pp")
        end

        def files
          @files ||= manifest_files
        end

        # the main file type that is used to help discover what the module is
        def self.file_type
          '.pp'
        end

      end
    end
  end
end