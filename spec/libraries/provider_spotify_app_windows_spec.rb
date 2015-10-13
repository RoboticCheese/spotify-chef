# Encoding: UTF-8

require_relative '../spec_helper'
require_relative '../../libraries/provider_spotify_app_windows'

describe Chef::Provider::SpotifyApp::Windows do
  let(:name) { 'default' }
  let(:run_context) { ChefSpec::SoloRunner.new.converge.run_context }
  let(:new_resource) { Chef::Resource::SpotifyApp.new(name, run_context) }
  let(:provider) { described_class.new(new_resource, run_context) }

  describe '.provides?' do
    let(:platform) { nil }
    let(:node) { ChefSpec::Macros.stub_node('node.example', platform) }
    let(:res) { described_class.provides?(node, new_resource) }

    context 'Windows' do
      let(:platform) { { platform: 'windows', version: '2012R2' } }

      it 'returns true' do
        expect(res).to eq(true)
      end
    end
  end

  describe '#install!' do
    before(:each) do
      [:download_package, :install_package].each do |m|
        allow_any_instance_of(described_class).to receive(m)
      end
    end

    it 'downloads the package' do
      expect_any_instance_of(described_class).to receive(:download_package)
      provider.send(:install!)
    end

    it 'installs the package' do
      expect_any_instance_of(described_class).to receive(:install_package)
      provider.send(:install!)
    end
  end

  describe '#remove!' do
    it 'raises an error' do
      expect { provider.send(:remove!) }.to raise_error(NotImplementedError)
    end
  end

  describe '#install_package' do
    before(:each) do
      allow_any_instance_of(described_class).to receive(:download_path)
        .and_return('/tmp/Spotify.exe')
    end

    it 'uses a windows_package to install the package' do
      p = provider
      expect(p).to receive(:windows_package).with('Spotify').and_yield
      expect(p).to receive(:source).with('/tmp/Spotify.exe')
      expect(p).to receive(:installer_type).with(:nsis)
      expect(p).to receive(:action).with(:install)
      p.send(:install_package)
    end
  end

  describe '#download_package' do
    before(:each) do
      allow_any_instance_of(described_class).to receive(:download_path)
        .and_return('/tmp/Spotify.exe')
    end

    it 'uses a remote_file to download the package' do
      p = provider
      expect(p).to receive(:remote_file).with('/tmp/Spotify.exe').and_yield
      expect(p).to receive(:source).with(described_class::URL)
      expect(p).to receive(:action).with(:create)
      expect(p).to receive(:only_if).and_yield
      expect(File).to receive(:exist?).with(described_class::PATH)
      p.send(:download_package)
    end
  end

  describe '#download_path' do
    it 'returns a path under the Chef cache dir' do
      res = provider.send(:download_path)
      expected = "#{Chef::Config[:file_cache_path]}/Spotify.exe"
      expect(res).to eq(expected)
    end
  end
end
