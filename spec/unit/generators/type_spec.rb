require 'spec_helper'

describe "type" do
  describe 'bmc' do
    let(:file) do
      File.join(fixtures_type_path , 'bmc.rb')
    end

    let(:models) do
      Retrospec::Puppet::Type.load_type(file)
    end

    it 'can eval code' do
      models = Retrospec::Puppet::Type.load_type(file)
      expect(models.name).to eq(:bmc)
    end

    it 'has correct amount of properties' do
      expect(models.properties).to eq([{:name=>:ipsource},
                                       {:name=>:ip},
                                       {:name=>:netmask},
                                       {:name=>:gateway},
                                       {:name=>:vlanid}]
                                   )
    end

    it 'has correct amount of parameters' do
      expect(models.parameters).to eq([{:name=>:name, :namevar=>true}])
    end

    it 'has the correct number of methods' do
      expect(models.methods_defined).to eq([:ensurable])
    end

    it 'has the correct number of instance methods' do
      expect(models.instance_methods).to eq([:validaddr?])
    end

  end

  describe 'bmcuser' do
    let(:file) do
      File.join(fixtures_type_path , 'bmcuser.rb')
    end

    let(:models) do
      Retrospec::Puppet::Type.load_type(file)
    end

    it 'can eval code' do
      models = Retrospec::Puppet::Type.load_type(file)
      expect(models.name).to eq(:bmcuser)
    end

    it 'has correct amount of properties' do
      expect(models.properties).to eq([{:name=>:id}, {:name=>:username, :namevar=>true},
                                       {:name=>:userpass}, {:name=>:privlevel}])

    end

    it 'has correct amount of parameters' do
      expect(models.parameters).to eq( [{:name=>:name}, {:name=>:force}])
    end

    it 'has the correct number of methods' do
      expect(models.methods_defined).to eq([:ensurable])
    end

    it 'has the correct number of instance methods' do
      expect(models.instance_methods).to eq([])
    end
  end

end