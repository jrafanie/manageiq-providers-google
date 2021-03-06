describe ManageIQ::Providers::Google::CloudManager::Refresher do
  before(:each) do
    _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
    @google_json_key = "{\n  \"type\": \"service_account\",\n  \"project_id\": \"civil-tube-113314\",\n  \"private_key_id\": \"bd99fda9d4a1e62f8371b7cd92ffcc6bb21ee453\",\n  \"private_key\": \"-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCR2KaVdHB3sMkm\\n8v8KZCPuKMvbUZ4oswT2ORRgm8hwJkMgvGpGAVnCRTwujXwm7ar7Acbopxzg4Qcm\\nb+DL6liyojrV3flbNiFcQniyMdjJxERyGKCEeLa+fGW9dNG2/v+2WAiQamywKgMA\\nlgR9bgaKZBPoDYIGpcwMqbXfCz/edUrWgf/sPw/EVePn56ARwEGE8azPyflP+tsM\\n2SskpW0SNJnHgwj3dKlH8iRXFTqGBaodM/864yb5IPTFkmR/3TPs9z+vbiyD/5zw\\nRbsSY9CRkP1ZU6qYn4KEbyv2eZ3J76oYJFUFWOPiKqNQBSdMX4+D2x7GlePEYnoV\\n5Zq9deTTAgMBAAECggEACaadGgADKTMTkcuRQNjGNTjnNHNpfyaeyhmWKvEOtGJz\\nyAjFEi4oswhDJo7KNlvnwoWoPzY/sknHCq4V4VMih2o2G8zSdqIAVyCMPWO7BVmY\\nGzdconzHwEHEYbhciuVuJQdyREwmi7Rb+n/y0Bylu3v1LUJ85iphHugOrDG3CjtT\\nH478PQePaJ+Gn4pByoyBV4NDQo1V5suFWmWRD3WKIr9kX2SE6UGZ5v+UCSDRwh+K\\nEttKqEdj2AYxxxohF9Do/a6jaJ8eXIa2HoeL2JoDyZwdUNVQzBiq+kLsrM911HOB\\nqoQ/uzzFs9gkEIv8PD9c1GGYcEaoS8ltofAJJZF7sQKBgQDIXebMKsin0Mg5ZasU\\nTsN/AkryG5alzh7D+qGaQ6ra/EsqSif1A7bLoFnUT3s4khCezseRnQNQrw96SYTv\\nD10qrp+74i0/8A/AoKw0bqR3+6XFewgN1LtQPtR4gwgvTJCzfZdExG06O1zYWaWt\\nIZAI77gcqIUr9ugH89bOgXXJPQKBgQC6V2yUSoGYnzOCqJgpuMbt9Nx7KFbgMPs1\\n7gkUxfxTfseadSgirxPTd0JXTtJjsV8r1Dn3G1VNcxK/3lNrVCAfDNshTVw3pcek\\nRpt4sxCC1cHhgiErvCF8hJ3LRqZdYDWOPBD28JGQgdHuLuwVXfSm51iZj3+fxTDZ\\nHxYh5I6nTwKBgC5hHgVwedXujApNMFaZDMOfgj2ciTiEB7cRksqkky3xbGyzkaAz\\nZeKokWKFq14i4VoBP0zDbXsFqq2ByxWTFtvEZBEXf6XnKZ5LEtFoMwXa6DpYCjs5\\nXMpsYL4shn58WJpTneo7FZV/HDSwO5thw3duFc38bCcLFhaRKM3QRbV5AoGBAIco\\nwmkNYdMCJqqu/y/EBwayhPoP2HPlE1Gaxpt6v/sQClfOgr4ln4vTBRuu4IvPK+ju\\nltzVxpnWzdK9wGQpMONUv9z379utM5HEZSC3QVKlGWwop0bBvshCqPG43RL9pdr1\\nVpjHBc57W3oYLsWQ0NP/GhTIMRoCPdw+4B7VWWOhAoGAYEdx3cnDpPOTH1179GTv\\ny/q1LXvp8nP50HZ1Yc+wAOnifXBKhSTpjDqgru5OiGT7rggzyK0ui3nyfbwM5AH7\\nyQXmt8q0Nnzo8GdL+YKTfGbnmSwDH0SotEeofwruPuxOr7ows6joo283NOugudsx\\nUAa/tB/piHG/VYQ6dxb8zsg=\\n-----END PRIVATE KEY-----\\n\",\n  \"client_email\": \"199203428544-compute@developer.gserviceaccount.com\",\n  \"client_id\": \"102455136987689387132\",\n  \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",\n  \"token_uri\": \"https://accounts.google.com/o/oauth2/token\",\n  \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",\n  \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/199203428544-compute%40developer.gserviceaccount.com\"\n}\n"
    @ems = FactoryGirl.create(:ems_google, :zone => zone)
    @ems.authentications << FactoryGirl.create(:authentication, :userid => "_", :auth_key => @google_json_key)
    @ems.update_attributes(:project => "civil-tube-113314")

    # A true thread may fail the test with VCR
    allow(Thread).to receive(:new) do |*args, &block|
      block.call(*args)
      Class.new do
        def join; end
      end.new
    end
  end

  it "will perform a full refresh" do
    2.times do # Run twice to verify that a second run with existing data does not change anything
      @ems.reload
      VCR.use_cassette(described_class.name.underscore, :allow_unused_http_interactions => true) do
        EmsRefresh.refresh(@ems)
        EmsRefresh.refresh(@ems.network_manager)
      end
      @ems.reload

      assert_table_counts
      assert_ems
      assert_specific_zone
      assert_specific_key_pair
      assert_specific_cloud_network
      assert_specific_cloud_subnet
      assert_specific_floating_ips
      assert_specific_load_balancer
      assert_specific_security_group
      assert_specific_flavor
      assert_specific_custom_flavor
      assert_specific_vm_powered_on
      assert_specific_vm_with_proper_subnets
      assert_specific_vm_powered_off
      assert_specific_vm_preemptible
      assert_specific_image_template
      assert_specific_snapshot_template
      assert_specific_cloud_volume
      assert_specific_cloud_volume_snapshot
    end
  end

  def expected_table_counts
    {
      :ext_management_system              => 2,
      :flavor                             => 22,
      :availability_zone                  => 24,
      :vm_or_template                     => 779,
      :vm                                 => 6,
      :miq_template                       => 773,
      :disk                               => 6,
      :guest_device                       => 0,
      :hardware                           => 6,
      :load_balancer                      => 1,
      :load_balancer_listener             => 1,
      :load_balancer_pool                 => 1,
      :load_balancer_pool_member          => 1,
      :load_balancer_health_checks        => 1,
      :load_balancer_health_check_members => 1,
      :network                            => 0,
      :operating_system                   => 779,
      :relationship                       => 11,
      :miq_queue                          => 780,
      :orchestration_template             => 0,
      :orchestration_stack                => 0,
      :orchestration_stack_parameter      => 0,
      :orchestration_stack_output         => 0,
      :orchestration_stack_resource       => 0,
      :security_group                     => 3,
      :network_port                       => 6,
      :cloud_network                      => 3,
      :floating_ip                        => 3,
      :network_router                     => 0,
      :cloud_subnet                       => 9,
      :key_pair                           => 4,
    }
  end

  def assert_table_counts
    actual                                = {
      :ext_management_system              => ExtManagementSystem.count,
      :flavor                             => Flavor.count,
      :availability_zone                  => AvailabilityZone.count,
      :vm_or_template                     => VmOrTemplate.count,
      :vm                                 => Vm.count,
      :miq_template                       => MiqTemplate.count,
      :disk                               => Disk.count,
      :guest_device                       => GuestDevice.count,
      :hardware                           => Hardware.count,
      :load_balancer                      => LoadBalancer.count,
      :load_balancer_listener             => LoadBalancerListener.count,
      :load_balancer_pool                 => LoadBalancerPool.count,
      :load_balancer_pool_member          => LoadBalancerPoolMember.count,
      :load_balancer_health_checks        => LoadBalancerHealthCheck.count,
      :load_balancer_health_check_members => LoadBalancerHealthCheckMember.count,
      :network                            => Network.count,
      :operating_system                   => OperatingSystem.count,
      :relationship                       => Relationship.count,
      :miq_queue                          => MiqQueue.count,
      :orchestration_template             => OrchestrationTemplate.count,
      :orchestration_stack                => OrchestrationStack.count,
      :orchestration_stack_parameter      => OrchestrationStackParameter.count,
      :orchestration_stack_output         => OrchestrationStackOutput.count,
      :orchestration_stack_resource       => OrchestrationStackResource.count,
      :security_group                     => SecurityGroup.count,
      :network_port                       => NetworkPort.count,
      :cloud_network                      => CloudNetwork.count,
      :floating_ip                        => FloatingIp.count,
      :network_router                     => NetworkRouter.count,
      :cloud_subnet                       => CloudSubnet.count,
      :key_pair                           => AuthPrivateKey.count,
    }

    expect(actual).to eq expected_table_counts
  end

  def assert_ems
    expect(@ems.flavors.size).to            eql(expected_table_counts[:flavor])
    expect(@ems.key_pairs.size).to          eql(expected_table_counts[:key_pair])
    expect(@ems.availability_zones.size).to eql(expected_table_counts[:availability_zone])
    expect(@ems.vms_and_templates.size).to  eql(expected_table_counts[:vm_or_template])
    expect(@ems.cloud_networks.size).to     eql(expected_table_counts[:cloud_network])
    expect(@ems.security_groups.size).to    eql(expected_table_counts[:security_group])
    expect(@ems.vms.size).to                eql(expected_table_counts[:vm])
    expect(@ems.miq_templates.size).to      eql(expected_table_counts[:miq_template])
  end

  def assert_specific_zone
    @zone = ManageIQ::Providers::Google::CloudManager::AvailabilityZone.find_by_ems_ref("us-east1-b")
    expect(@zone).to have_attributes(
      :name   => "us-east1-b",
      :ems_id => @ems.id
    )

    @zone_central = ManageIQ::Providers::Google::CloudManager::AvailabilityZone.find_by_ems_ref("us-central1-b")
    expect(@zone_central).to have_attributes(
      :name   => "us-central1-b",
      :ems_id => @ems.id
    )
  end

  def assert_specific_key_pair
    # Find an ssh key added to a single vm
    @kp = ManageIQ::Providers::Google::CloudManager::AuthKeyPair.where(:name => "root").first
    expect(@kp).to have_attributes(
      :name        => "root",
      :fingerprint => "97:c9:58:c8:42:32:3d:e1:47:a9:e6:66:93:51:6a:ae:a9:cb:ee:4a"
    )

    # Find an ssh key added to the whole project
    @project_kp = ManageIQ::Providers::Google::CloudManager::AuthKeyPair.where(:name => "user2").first
    expect(@project_kp).to have_attributes(
      :name        => "user2",
      :fingerprint => "db:46:06:c9:4b:af:d7:18:b4:1d:d0:af:bc:d6:2e:26:48:bc:7d:17"
    )
  end

  def assert_specific_cloud_network
    @cn = CloudNetwork.where(:name => "default").first
    expect(@cn).to have_attributes(
      :name    => "default",
      :ems_ref => "183954628405178359",
      :cidr    => "10.240.0.0/16",
      :status  => "active",
      :enabled => true
    )
  end

  def assert_specific_cloud_subnet
    @cs = CloudSubnet.where(:name => "default").first
    expect(@cs).to have_attributes(
      :name             => "default",
      :ems_ref          => "183954628405178359",
      :cidr             => "10.240.0.0/16",
      :gateway          => "10.240.0.1",
      :status           => "active",
      :cloud_network_id => @cn.id
    )
  end

  def assert_specific_floating_ips
    @assigned_floating_ip = FloatingIp.where(:address => "104.197.50.240").first
    expect(@assigned_floating_ip.vm).not_to eql(nil)
    expect(@assigned_floating_ip.network_port.device).not_to eql(nil)

    unassigned_floating_ip = FloatingIp.where(:address => "104.196.55.145").first
    expect(unassigned_floating_ip.vm).to eql(nil)
    expect(unassigned_floating_ip.network_port).to eql(nil)
  end

  def assert_specific_load_balancer
    lb = LoadBalancer.where(:name => "foo-lb-forwarding-rule").first

    expect(lb).to have_attributes(
      :name    => "foo-lb-forwarding-rule",
      :ems_ref => "1778652908557222005",
      :type    => "ManageIQ::Providers::Google::NetworkManager::LoadBalancer"
    )
    expect(lb.load_balancer_listeners.first).to have_attributes(
      :name                     => "foo-lb-forwarding-rule",
      :ems_ref                  => "1778652908557222005",
      :type                     => "ManageIQ::Providers::Google::NetworkManager::LoadBalancerListener",
      :load_balancer_protocol   => "TCP",
      :instance_protocol        => "TCP",
      :load_balancer_port_range => 61000...61002,
      :instance_port_range      => 61000...61002
    )
    expect(lb.load_balancer_pools.first).to have_attributes(
      :name    => "foo-lb",
      :ems_ref => "7341375068641214585",
      :type    => "ManageIQ::Providers::Google::NetworkManager::LoadBalancerPool",
    )
    expect(lb.load_balancer_pool_members.map { |m| m.vm.name })
      .to include("subnet-test")
    expect(lb.load_balancer_health_checks.first).to have_attributes(
      :name                => "foo-healthcheck",
      :type                => "ManageIQ::Providers::Google::NetworkManager::LoadBalancerHealthCheck",
      :ems_ref             => "1778652908557222005_7341375068641214585_5620697980296979925",
      :protocol            => "HTTP",
      :port                => 80,
      :url_path            => "/foopath",
      :interval            => 60,
      :timeout             => 30,
      :healthy_threshold   => 2,
      :unhealthy_threshold => 3)
    expect(lb.load_balancer_health_checks.first.load_balancer_health_check_members.first).to have_attributes(
      :status => "OutOfService"
    )
    expect(lb.load_balancer_health_checks.first.load_balancer_health_check_members.first.load_balancer_pool_member.vm.name)\
      .to eql("subnet-test")
  end

  def assert_specific_security_group
    @sg = SecurityGroup.where(:name => "default").first
    expect(@sg).to have_attributes(
      :name    => "default",
      :ems_ref => "default"
    )

    expected_firewall_rules = [
      {
        :name            => "default-allow-icmp",
        :host_protocol   => "ICMP",
        :direction       => "inbound",
        :port            => -1,
        :end_port        => -1,
        :source_ip_range => "0.0.0.0/0"
      },
      {
        :name            => "default-allow-internal",
        :host_protocol   => "ICMP",
        :direction       => "inbound",
        :port            => -1,
        :end_port        => -1,
        :source_ip_range => "10.240.0.0/16"
      },
      {
        :name            => "default-allow-internal",
        :host_protocol   => "TCP",
        :direction       => "inbound",
        :port            => 0,
        :end_port        => 65535,
        :source_ip_range => "10.240.0.0/16"
      },
      {
        :name            => "default-allow-internal",
        :host_protocol   => "UDP",
        :direction       => "inbound",
        :port            => 0,
        :end_port        => 65535,
        :source_ip_range => "10.240.0.0/16"
      },
      {
        :name            => "default-allow-rdp",
        :host_protocol   => "TCP",
        :direction       => "inbound",
        :port            => 3389,
        :end_port        => nil,
        :source_ip_range => "0.0.0.0/0"
      },
      {
        :name            => "default-allow-ssh",
        :host_protocol   => "TCP",
        :direction       => "inbound",
        :port            => 22,
        :end_port        => nil,
        :source_ip_range => "0.0.0.0/0"
      },
    ]

    expect(@sg.firewall_rules.size).to eq(6)

    ordered_fw_rules = @sg.firewall_rules.order(
      :name, :host_protocol, :direction, :port, :end_port, :source_ip_range)

    ordered_fw_rules.zip(expected_firewall_rules).each do |actual, expected|
      expect(actual).to have_attributes(expected)
    end
  end

  def assert_specific_flavor
    @flavor = ManageIQ::Providers::Google::CloudManager::Flavor.where(:name => "f1-micro").first
    expect(@flavor).to have_attributes(
      :name        => "f1-micro",
      :ems_ref     => "f1-micro",
      :description => "1 vCPU (shared physical core) and 0.6 GB RAM",
      :enabled     => true,
      :cpus        => 1,
      :memory      => 643825664,
    )

    expect(@flavor.ext_management_system).to eq(@ems)
  end

  def assert_specific_custom_flavor
    custom_flavor = ManageIQ::Providers::Google::CloudManager::Flavor.where(:name => "custom-1-2048").first
    expect(custom_flavor).to have_attributes(
      :name        => "custom-1-2048",
      :ems_ref     => "custom-1-2048",
      :description => "Custom created machine type.",
      :enabled     => true,
      :cpus        => 1,
      :memory      => 2147483648,
    )

    expect(custom_flavor.ext_management_system).to eq(@ems)
    expect(custom_flavor.vms.count).to             eq(1)
    expect(custom_flavor.vms.first.name).to        eq("instance-custom-machine-type")
  end

  def assert_specific_vm_powered_on
    v = ManageIQ::Providers::Google::CloudManager::Vm.where(:name => "rhel7", :raw_power_state => "RUNNING").first
    expect(v).to have_attributes(
      :template              => false,
      :ems_ref               => "5220078748954475260",
      :ems_ref_obj           => nil,
      :uid_ems               => "5220078748954475260",
      :vendor                => "google",
      :power_state           => "on",
      :location              => "unknown",
      :tools_status          => nil,
      :boot_time             => nil,
      :standby_action        => nil,
      :connection_state      => nil,
      :cpu_affinity          => nil,
      :memory_reserve        => nil,
      :memory_reserve_expand => nil,
      :memory_limit          => nil,
      :memory_shares         => nil,
      :memory_shares_level   => nil,
      :cpu_reserve           => nil,
      :cpu_reserve_expand    => nil,
      :cpu_limit             => nil,
      :cpu_shares            => nil,
      :cpu_shares_level      => nil
    )

    expect(v.ext_management_system).to         eql(@ems)
    expect(v.availability_zone).to             eql(@zone)
    expect(v.flavor).to                        eql(@flavor)
    expect(v.operating_system.product_name).to eql("linux_redhat")
    expect(v.custom_attributes.size).to        eql(0)
    expect(v.snapshots.size).to                eql(0)
    expect(v.preemptible?).to                  eql(false)

    assert_specific_vm_powered_on_hardware(v)
  end

  def assert_specific_vm_powered_on_hardware(v)
    expect(v.hardware).to have_attributes(
      :guest_os            => nil,
      :guest_os_full_name  => nil,
      :bios                => nil,
      :annotation          => nil,
      :cpu_total_cores     => 1,
      :memory_mb           => 614,
      :bitness             => nil,
      :virtualization_type => nil
    )

    expect(v.hardware.guest_devices.size).to eql(0)
    expect(v.hardware.nics.size).to          eql(0)

    assert_specific_vm_powered_on_networks(v)
    assert_specific_vm_powered_on_hardware_disks(v)
  end

  def assert_specific_vm_powered_on_networks(v)
    expect(v.cloud_networks.size).to eql(1)
    expect(v.cloud_subnets.size).to  eql(1)
    expect(v.floating_ips.size).to   eql(1)
    expect(v.network_ports.size).to  eql(1)
    expect(v.ipaddresses.size).to    eql(2)

    expect(v.network_ports.first.ipaddresses.first).to eq('10.240.0.2')

    network = v.cloud_networks.where(:name => 'default').first
    expect(network).to have_attributes(
      :cidr     => "10.240.0.0/16",
    )

    subnet = v.cloud_subnets.where(:name => "default").first
    expect(subnet).to have_attributes(
      :cidr             => "10.240.0.0/16",
      :gateway          => "10.240.0.1",
      :cloud_network_id => network.id
    )
  end

  def assert_specific_vm_powered_on_hardware_disks(v)
    expect(v.hardware.disks.size).to eql(1)

    disk = v.hardware.disks.first
    expect(disk).to have_attributes(
      :device_name     => "rhel7",
      :device_type     => "disk",
      :location        => "0",
      :controller_type => "google",
      :size            => 10.gigabyte,
      :backing_type    => "CloudVolume"
    )
    expect(disk.backing).to eql(CloudVolume.where(:name => "rhel7").first)
  end

  def assert_specific_vm_with_proper_subnets
    v = ManageIQ::Providers::Google::CloudManager::Vm.where(:name => "subnet-test", :raw_power_state => "RUNNING").first
    expect(v).to have_attributes(
      :template              => false,
      :ems_ref               => "6019338445080368070",
      :ems_ref_obj           => nil,
      :uid_ems               => "6019338445080368070",
      :vendor                => "google",
      :power_state           => "on",
      :location              => "unknown",
      :tools_status          => nil,
      :boot_time             => nil,
      :standby_action        => nil,
      :connection_state      => nil,
      :cpu_affinity          => nil,
      :memory_reserve        => nil,
      :memory_reserve_expand => nil,
      :memory_limit          => nil,
      :memory_shares         => nil,
      :memory_shares_level   => nil,
      :cpu_reserve           => nil,
      :cpu_reserve_expand    => nil,
      :cpu_limit             => nil,
      :cpu_shares            => nil,
      :cpu_shares_level      => nil
    )

    expect(v.ext_management_system).to                  eql(@ems)
    expect(v.availability_zone).to                      eql(@zone_central)
    expect(v.flavor).to                                 eql(@flavor)
    expect(v.operating_system.product_name).to          eql("linux_debian")
    expect(v.floating_ip).to                            eql(@assigned_floating_ip)
    expect(v.floating_ips.first).to                     eql(@assigned_floating_ip)
    expect(v.network_ports.first.floating_ip).to        eql(@assigned_floating_ip)
    expect(v.network_ports.first.floating_ips.first).to eql(@assigned_floating_ip)
  end

  def assert_specific_cloud_volume
    v = CloudVolume.where(
      :name            => "rhel7"
    ).first

    expect(v.ems_ref).to                 eql("7616431006268085360")
    expect(v.name).to                    eql("rhel7")
    expect(v.status).to                  eql("READY")
    expect(v.creation_time.to_s).to      eql("2015-11-18 21:16:15 UTC")
    expect(v.volume_type).to             eql("pd-standard")
    expect(v.description).to             eql(nil)
    expect(v.size).to                    eql(10.gigabyte)
    expect(v.availability_zone.name).to  eql("us-east1-b")
  end

  def assert_specific_cloud_volume_snapshot
    v = CloudVolumeSnapshot.where(:name => "wheezy-snapshot-1").first
    expect(v.ems_ref).to            eql("9048940034142591751")
    expect(v.name).to               eql("wheezy-snapshot-1")
    expect(v.description).to        be_nil
    expect(v.status).to             eql("READY")
    expect(v.creation_time.to_s).to eql("2015-11-18 20:56:08 UTC")
    expect(v.size).to               eql(10.gigabyte)
  end

  def assert_specific_vm_powered_off
    v = ManageIQ::Providers::Google::CloudManager::Vm.where(
      :name            => "wheezy",
      :raw_power_state => "TERMINATED").first

    zone1 = ManageIQ::Providers::Google::CloudManager::AvailabilityZone.where(:name => "us-central1-b").first

    assert_specific_vm_powered_off_attributes(v)

    expect(v.ext_management_system).to         eql(@ems)
    expect(v.availability_zone).to             eql(zone1)
    expect(v.floating_ip).to                   be_nil
    expect(v.cloud_network).to                 eql(@cn)
    expect(v.cloud_networks.first).to          eql(@cn)
    expect(v.cloud_subnet).to                  eql(@cs)
    expect(v.cloud_subnets.first).to           eql(@cs)
    expect(v.operating_system.product_name).to eql("linux_debian")
    # This should have keys added on just this vm (@kp) as well as
    # on the whole project (@project_kp)
    expect(v.key_pairs.to_a).to                eql([@kp, @project_kp])
    expect(v.custom_attributes.size).to        eql(0)
    expect(v.snapshots.size).to                eql(0)

    assert_specific_vm_powered_off_hardware(v)
  end

  def assert_specific_vm_powered_off_attributes(v)
    expect(v).to have_attributes(
      :template              => false,
      :ems_ref               => "17122958274615180727",
      :ems_ref_obj           => nil,
      :uid_ems               => "17122958274615180727",
      :vendor                => "google",
      :power_state           => "off",
      :location              => "unknown",
      :tools_status          => nil,
      :boot_time             => nil,
      :standby_action        => nil,
      :connection_state      => nil,
      :cpu_affinity          => nil,
      :memory_reserve        => nil,
      :memory_reserve_expand => nil,
      :memory_limit          => nil,
      :memory_shares         => nil,
      :memory_shares_level   => nil,
      :cpu_reserve           => nil,
      :cpu_reserve_expand    => nil,
      :cpu_limit             => nil,
      :cpu_shares            => nil,
      :cpu_shares_level      => nil
    )
  end

  def assert_specific_vm_powered_off_hardware(v)
    expect(v.hardware).to have_attributes(
      :guest_os           => nil,
      :guest_os_full_name => nil,
      :bios               => nil,
      :annotation         => nil,
      :memory_mb          => 614,
      :cpu_total_cores    => 1,
      :bitness            => nil
    )

    expect(v.hardware.disks.size).to         eql(1)
    expect(v.hardware.guest_devices.size).to eql(0)
    expect(v.network_ports.size).to          eql(1)
    expect(v.cloud_networks.size).to         eql(1)
    expect(v.floating_ips.size).to           eql(0)
  end

  def assert_specific_vm_preemptible
    v = ManageIQ::Providers::Google::CloudManager::Vm.where(:name => "preemptible-1").first
    expect(v).to have_attributes(
      :raw_power_state => "TERMINATED",
      :template        => false,
      :ems_ref         => "9023820458355785494",
      :uid_ems         => "9023820458355785494",
      :vendor          => "google",
      :power_state     => "off"
    )

    expect(v.preemptible?).to eql(true)
  end

  def assert_specific_image_template
    name      = "rhel-7-v20151104"
    @template = ManageIQ::Providers::Google::CloudManager::Template.where(:name => name).first
    expected_location = "https://www.googleapis.com/compute/v1/projects/rhel-cloud/global/images/rhel-7-v20151104"

    expect(@template).to have_attributes(
      :template              => true,
      :ems_ref               => "5670907071397924697",
      :ems_ref_obj           => nil,
      :uid_ems               => "5670907071397924697",
      :vendor                => "google",
      :power_state           => "never",
      :location              => expected_location,
      :tools_status          => nil,
      :boot_time             => nil,
      :standby_action        => nil,
      :connection_state      => nil,
      :cpu_affinity          => nil,
      :memory_reserve        => nil,
      :memory_reserve_expand => nil,
      :memory_limit          => nil,
      :memory_shares         => nil,
      :memory_shares_level   => nil,
      :cpu_reserve           => nil,
      :cpu_reserve_expand    => nil,
      :cpu_limit             => nil,
      :cpu_shares            => nil,
      :cpu_shares_level      => nil
    )

    expect(@template.ext_management_system).to         eq(@ems)
    expect(@template.operating_system.product_name).to eq("linux_redhat")
    expect(@template.custom_attributes.size).to        eq(0)
    expect(@template.snapshots.size).to                eq(0)
  end

  def assert_specific_snapshot_template
    name      = "wheezy-snapshot-1"
    @template = ManageIQ::Providers::Google::CloudManager::Template.where(:name => name).first
    expected_location =
      "https://www.googleapis.com/compute/v1/projects/civil-tube-113314/global/snapshots/wheezy-snapshot-1"

    expect(@template).to have_attributes(
      :template              => true,
      :ems_ref               => "9048940034142591751",
      :ems_ref_obj           => nil,
      :uid_ems               => "9048940034142591751",
      :vendor                => "google",
      :power_state           => "never",
      :location              => expected_location,
      :tools_status          => nil,
      :boot_time             => nil,
      :standby_action        => nil,
      :connection_state      => nil,
      :cpu_affinity          => nil,
      :memory_reserve        => nil,
      :memory_reserve_expand => nil,
      :memory_limit          => nil,
      :memory_shares         => nil,
      :memory_shares_level   => nil,
      :cpu_reserve           => nil,
      :cpu_reserve_expand    => nil,
      :cpu_limit             => nil,
      :cpu_shares            => nil,
      :cpu_shares_level      => nil
    )

    expect(@template.ext_management_system).to         eq(@ems)
    expect(@template.operating_system.product_name).to eq("unknown")
    expect(@template.custom_attributes.size).to        eq(0)
    expect(@template.snapshots.size).to                eq(0)
  end
end
