require 'spec_helper'

describe "type generator" do

  before :each do
    FileUtils.rm_rf(type_spec_dir)
    allow(generator).to receive(:type_dir).and_return(fixtures_type_path)
    allow(generator).to receive(:type_name_path).and_return(File.join(module_path, 'lib', 'puppet', 'type', "#{generator.type_name}.rb"))
  end

  after :each do
    FileUtils.rm_f(generator.type_name_path) # ensure the file does not exist
  end

  let(:type_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'puppet', 'type')
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:context) do
    {:name => 'vhost', :properties => ['config1', 'config2'], :parameters => ['prop1', 'prop2'],
     :template_dir => File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates'))}
  end

  let(:generator) do
    Retrospec::Puppet::Generators::TypeGenerator.new(module_path, context )
  end

  it 'returns type dir' do
    expect(generator.type_dir).to eq(fixtures_facts_path)
  end

  it 'returns module path' do
    expect(generator.type_spec_dir).to eq(type_spec_dir)
  end

  it 'can return type name' do
    expect(generator.type_name).to eq('vhost')
  end

  it 'can generate a type file' do
    expect(generator.generate_type_files).to eq(nil)
    expect(File.exists?(File.join(generator.type_dir, "#{generator.type_name}.rb")))
  end

  it 'can generate a spec file' do
    expect(generator.generate_type_spec_files).to eq(["/Users/cosman/github/puppet-retrospec/spec/fixtures/modules/tomcat/spec/unit/puppet/type/bmc_spec.rb",
                                                      "/Users/cosman/github/puppet-retrospec/spec/fixtures/modules/tomcat/spec/unit/puppet/type/bmcuser_spec.rb"])
    binding.pry
  end

end