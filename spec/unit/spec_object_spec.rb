require 'spec_helper'

describe 'spec_object' do

  let(:path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:opts) do
    { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
      :enable_user_templates => false, :template_dir => '/tmp/.retrospec_templates' }
  end

  it 'should create files without error' do
    mod = Retrospec::Plugins::V1::Puppet.new(opts[:module_path], opts)
    mod.post_init
    binding.pry
  end

end