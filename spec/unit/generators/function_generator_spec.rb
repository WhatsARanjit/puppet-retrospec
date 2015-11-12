require 'spec_helper'

describe 'function_generator' do
  before :each do
    FileUtils.rm_rf(generator.v3_spec_dir)
    FileUtils.rm_rf(generator.v4_spec_dir)
    FileUtils.rm_rf(function_path)
  end

  let(:function_path) do
    File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
  end

  let(:module_path) do
    sample_module_path
  end

  let(:context) do
    { :module_path => module_path,
      :template_dir => template_dir }
  end

  let(:template_dir) do
    File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates'))
  end

  let(:function_name) do
    'awesome_parser'
  end

  let(:type_name) do
    'v4'
  end

  let(:return_type) do
    'rvalue'
  end

  let(:cli_opts) do
    ARGV.push('-n')
    ARGV.push(function_name)
    ARGV.push('-r')
    ARGV.push(return_type)
    ARGV.push('-t')
    ARGV.push(type_name)
    Retrospec::Puppet::Generators::FunctionGenerator.run_cli(context)
  end

  let(:generator) do
    Retrospec::Puppet::Generators::FunctionGenerator.new(module_path, cli_opts)
  end

  it 'contain template dir' do
    expect(generator.template_dir).to match /templates\/functions/
  end

  it 'returns function name' do
    expect(generator.function_name).to eq(function_name)
  end

  it 'generate spec files' do
    files = [File.join(generator.v3_spec_dir, 'defined_spec.rb'),
             File.join(generator.v3_spec_dir, 'sha1_spec.rb'),
             File.join(generator.v4_spec_dir, 'reduce_spec.rb'),
             File.join(generator.v4_spec_dir, 'awesome_parser_spec.rb')

    ]
    expect(generator.generate_spec_files).to match_array(files)
  end

  it 'returns found function files' do
    files = [
      File.join(module_path, 'lib', 'puppet', 'functions', 'awesome_parser.rb'),
      File.join(module_path, 'lib', 'puppet', 'functions', 'reduce.rb'),
      File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'bad_sha1.rb'),
      File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'defined.rb'),
      File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'sha1.rb'),
    ]
    expect(generator.discovered_functions).to match_array(files)
  end

  describe 'v3' do
    let(:type_name) do
      'v3'
    end

    let(:function_path) do
      File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
    end

    it 'returns function directory' do
      path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions')
      expect(generator.function_dir).to eq(path)
    end

    it 'returns function path' do
      path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
      expect(generator.function_path).to eq(path)
    end

    it 'generate function file' do
      expect(generator.generate_function_file).to eq(function_path)
    end

    it 'returns spec file directory' do
      path = File.join(module_path, 'spec', 'unit', 'puppet', 'parser', 'functions')
      expect(generator.spec_file_dir).to eq(path)
    end

  end

  describe 'v4' do
    let(:type_name) do
      'v4'
    end

    let(:function_path) do
      File.join(module_path, 'lib', 'puppet', 'functions', "#{function_name}.rb")
    end

    it 'returns function path' do
      path = File.join(module_path, 'lib', 'puppet', 'functions', "#{function_name}.rb")
      expect(generator.function_path).to eq(path)
    end

    it 'returns spec file directory' do
      path = File.join(module_path, 'spec', 'unit', 'puppet', 'functions')
      expect(generator.spec_file_dir).to eq(path)
    end

    it 'returns function directory' do
      path = File.join(module_path, 'lib', 'puppet', 'functions')
      expect(generator.function_dir).to eq(path)
    end

    it 'generate function file' do
      expect(generator.generate_function_file).to eq(function_path)
    end

  end
end

