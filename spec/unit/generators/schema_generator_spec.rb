require 'spec_helper'

describe 'schema_generator' do

  before(:each) do
    FileUtils.rm(schema_file)
  end

  let(:generator_opts) do
    {:name => 'test', :puppet_context => puppet_context}
  end

  let(:module_path) do
    sample_module_path
  end

  let(:schema_file) do
    path = File.join(module_path, 'tomcat_schema.yaml')
  end

  let(:puppet_context) do
    path = File.join(fixture_modules_path, 'tomcat')
    opts = { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
      :enable_user_templates => false, :template_dir => '/tmp/.retrospec_templates' }
    mod = Retrospec::Plugins::V1::Puppet.new(opts[:module_path], opts)
    mod.post_init
    mod.context
  end

  let(:generator) do
    Retrospec::Puppet::Generators::SchemaGenerator.new(module_path, generator_opts)
  end

  it 'should create files without error' do
    expect(generator.generate_schema_file).to eq(schema_file)
    puts File.read(schema_file)
  end
end
