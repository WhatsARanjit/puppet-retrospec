require 'spec_helper'

describe 'report_generator' do

  after(:each) do
    FileUtils.rm(report_file) if File.exists?(report_file)
  end

  let(:generator_opts) do
    {:name => 'test',  :template_dir => retrospec_templates_path}
  end

  let(:module_path) do
    sample_module_path
  end

  let(:report_file) do
    path = File.join(module_path, 'lib', 'puppet', 'reports', 'test.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::ReportGenerator.new(module_path, generator_opts)
  end

  it 'should create files without error' do
    expect(generator.run).to eq(report_file)
    expect(File.exists?(report_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_path).to eq(report_file)
  end

end
