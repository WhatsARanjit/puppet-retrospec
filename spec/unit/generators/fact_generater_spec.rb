require 'spec_helper'

describe "fact generator" do

  before :each do
    FileUtils.rm_rf(facter_spec_dir)
    allow(generator).to receive(:facter_dir).and_return(fixtures_facts_path)
    allow(generator).to receive(:fact_name_path).and_return(File.join(module_path, 'lib', 'facter', "#{generator.fact_name}.rb"))
  end

  after :each do
    FileUtils.rm_f(generator.fact_name_path) # ensure the file does not exist
  end

  let(:facter_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'facter')
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:context) do
    {:fact_name => 'datacenter'}
  end

  let(:generator) do
    Retrospec::Puppet::Generators::FactGenerator.new(module_path, context )
  end

  it 'returns facter dir' do
    expect(generator.facter_dir).to eq(fixtures_facts_path)
  end

  it 'returns module path' do
    expect(generator.facter_spec_dir).to eq(facter_spec_dir)
  end

  it 'can return fact name' do
    expect(generator.fact_name).to eq('datacenter')
  end

  it 'can generate a fact file' do
    expect(generator.generate_fact_file).to eq(nil)
    expect(File.exists?(File.join(generator.facter_dir, "#{generator.fact_name}.rb")))
  end

  it 'can generate a spec file' do

    #expect(generator).to receive(:safe_create_template_file).with(File.join(facter_spec_dir, 'fact1_spec.rb'), File.join(generator.template_dir, 'fact_spec.rb.retrospec.erb'))
    expect(generator.generate_fact_spec_files).to eq(nil)
  end

end