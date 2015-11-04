require_relative 'parsers/type'


module Retrospec
  module Puppet
    module Generators
      class TypeGenerator < Retrospec::Plugins::V1::Plugin
        attr_reader :template_dir, :context

        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object={})
          super
          # below is the Spec Object which serves as a context for template rendering
          # you will need to initialize this object, so the erb templates can get the binding
          # the SpecObject can be customized to your liking as its different for every plugin gem.
          @context = OpenStruct.new(:type_name => spec_object[:name], :parameters => spec_object[:parameters],
                                    :properties => spec_object[:properties])
        end

        def template_dir
          unless @template_dir
            external_templates = File.expand_path(File.join(config_data[:template_dir], 'types', 'type_template.rb.retrospec.erb'))
            if File.exists?(external_templates)
              @template_dir = File.join(config_data[:template_dir], 'types')
            else
              @template_dir = File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', 'types'))
            end
          end
          @template_dir
        end
        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns a new instance of this class
        def self.run_cli(global_opts)
          sub_command_opts = Trollop::options do
            banner <<-EOS
Generates a new type with the given name, and a default provider

            EOS
            opt :name, "The name of the type you wish to create", :type => :string, :required => false, :short => '-n',
                :default => File.basename(global_opts[:module_path])
            opt :parameters, "A list of parameters to initialize your type with", :type => Array, :required => false,
                :short => '-p', :default => []
            opt :properties, "A list of properties to initialize your type with", :type => Array, :required => false,
                :short => '-a', :default => []
            opt :providers, "A list of providers to create and associate with this type",:type => Array,
                default => ['default'], :required => false
          end
          unless sub_command_opts[:name]
            Trollop.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          Retrospec::Puppet::Generators::TypeGenerator.new(plugin_data[:module_path], plugin_data)
        end

        def type_dir
          @facter_dir ||= File.join(module_path, 'lib', 'puppet', 'type')
        end

        def type_spec_dir
          @type_spec_dir ||= File.join(module_path, 'spec', 'unit', 'puppet', 'type')
        end

        def type_name_path
          File.join(type_dir, "#{type_name}.rb")
        end

        def type_name
          context.type_name
        end

        def generate_type_files
          safe_create_template_file(type_name_path, File.join(template_dir, 'type_template.rb.retrospec.erb'), context)
        end

        # this will look through all
        def generate_type_spec_files
          type_files = Dir.glob(File.join(type_dir, '**', '*.rb')).sort
          spec_files = []
          type_files.each do |type_file|
            type_file_data = Retrospec::Puppet::Type.load_type(type_file)
            # because many facts can be in a single file we want to create a unique file for each fact
            type_spec_path = File.join(type_spec_dir, "#{type_file_data.name}_spec.rb")
            spec_files << type_spec_path
            safe_create_template_file(type_spec_path, File.join(template_dir, 'type_spec.rb.retrospec.erb'), type_file_data)
          end
          spec_files
        end

      end
    end
  end
end
