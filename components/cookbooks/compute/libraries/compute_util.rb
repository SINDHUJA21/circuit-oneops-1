# Exit the chef application process with the given error message
#
# @param : msg -  Error message
#
def exit_with_error(msg)
  puts "***FAULT:FATAL=#{msg}"
  Chef::Application.fatal!(msg)
end

def execute_command(command, force_failure = nil, timeout = nil)
  sh = Mixlib::ShellOut.new(command)
  sh.timeout = timeout if timeout
  result = sh.run_command
  if !result.valid_exit_codes.include?(result.exitstatus)
    if force_failure
      exit_with_error("Error in #{command}: #{result.stderr.gsub(/\n+/, '.')}")
    else
      Chef::Log.warn("Error in #{command}: #{result.stderr.gsub(/\n+/, '.')}")
    end
  end
  result
end

# get enabled network using the openstack compute cloud service
def get_enabled_network(compute_service,attempted_networks)

  has_sdn = true
  enabled_networks = []
  if compute_service.has_key?('enabled_networks')
    enabled_networks = JSON.parse(compute_service['enabled_networks'])
  end

  if enabled_networks.nil? || enabled_networks.empty?
    enabled_networks = [ compute_service['subnet'] ]
  end

  enabled_networks = enabled_networks - attempted_networks

  if enabled_networks.size == 0
    exit_with_error "no ip available in enabled networks for cloud #{node[:workorder][:cloud][:ciName]}. tried: #{attempted_networks} - escalate to openstack team"
  end

  network_name = enabled_networks.sample
  Chef::Log.info("network_name: "+network_name)

  # net_id for specifying network to use via subnet attr
  net_id = ''
  begin
    domain = compute_service.key?('domain') ? compute_service[:domain] : 'default'
    
    quantum = Fog::Network.new({
      :provider => 'OpenStack',
      :openstack_api_key => compute_service[:password],
      :openstack_username => compute_service[:username],
      :openstack_tenant => compute_service[:tenant],
      :openstack_auth_url => compute_service[:endpoint],
      :openstack_project_name => compute_service[:tenant],
      :openstack_domain_name => domain
    })

    quantum.networks.each do |net|
      if net.name == network_name
        Chef::Log.info("network_id: "+net.id)
        net_id = net.id
        break
      end
    end
  rescue Exception => e
    Chef::Log.warn("no quantum or neutron networking installed")
    has_sdn = false
  end
   
  exit_with_error "Your #{node[:workorder][:cloud][:ciName]} cloud is configured to use network: #{compute_service[:subnet]} but is not found." if net_id.empty? && has_sdn

  return network_name, net_id
end

def is_propagate_update
  rfcCi = node.workorder.rfcCi
  if (rfcCi.ciBaseAttributes.nil? || rfcCi.ciBaseAttributes.empty?) && rfcCi.has_key?('hint') && !rfcCi.hint.empty?
    hint = JSON.parse(rfcCi.hint)
    puts "rfc hint >> " + rfcCi.hint.inspect
    if hint.has_key?('propagation') && hint['propagation'] == 'true'
      return true;
    end
  end
  return false
end

def find_latest_image(images, pattern, pattern_snap)
  return_image = nil
  if pattern_snap.nil?
    pattern_snap = /(?!x)x/
  end
  images.each do |image|
    if image.name =~ pattern && image.name !~ pattern_snap && image.name !~ /-raw/i
      # break up name into its parts
      image_name_parts = image.name.split('-')

      # get age
      age_current = "#{image_name_parts[4].gsub(/v/, "")}#{image_name_parts[5]}".to_i

      # check against saved if exists
      if return_image.nil?
        return_image = image
      else
        age_old =  "#{(return_image.name.split('-'))[4].gsub(/v/, "")}#{(return_image.name.split('-'))[5]}".to_i
        if age_current > age_old
          return_image = image
        end
      end
    end
  end
  return return_image
end

def get_image(images, flavor, flag_FAST_IMAGE, flag_TESTING_MODE, default_image, custom_id, ostype)
  if flag_FAST_IMAGE.to_s.downcase == "true" && (flavor.nil? || flavor.name.downcase !~ /baremetal/i) && !custom_id
    pattern = /[a-zA-Z]{1,20}-#{ostype.gsub(/\./, "")}-\d{4}-v\d{8}-\d{4}/i

    # if testing mode true; consider snapshots but still take the latest image
    # else do not consider snapshots
    flag_TESTING_MODE.to_s.downcase == "true" ? pattern_snap = nil : pattern_snap = /snapshot/i

    filtered_fast_images = images.select { |image| image unless image.name.include? 'custom-' }
    return_image = find_latest_image(filtered_fast_images, pattern, pattern_snap)

    if return_image.nil?
      return default_image
    else
      return return_image
    end

  else
    return default_image

  end
end

def get_azure_connection(creds)
  # connection
  token_provider         = MsRestAzure::ApplicationTokenProvider.new(creds[:tenant_id], creds[:client_id], creds[:client_secret])
  credentials            = MsRest::TokenCredentials.new(token_provider)
  client                 = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
  client.subscription_id = creds[:subscription_id]

  client
end

def get_custom_image(images, ostype, image_id)
  # First filter out images based on OS Type
  filtered_custom_images = images.select { |image| image.name.include? "custom-#{ostype.tr('.', '')}-" }

  return nil if filtered_custom_images.size.zero?

  # If the image ID contains ID of a specific version of the OS. For e.g., Custom:Redhat:7.3:xxxxx
  return filtered_custom_images.select { |image| image.name.include? "-#{image_id[3]}" }.first unless image_id[3].eql? 'latest'

  # Find the latest image uploaded for that OS type
  pattern = /[a-zA-Z]{1,20}-#{ostype.tr('.', '')}-\d{4}-v\d{8}-\d{4}/i

  custom_image = find_latest_image(filtered_custom_images, pattern, nil)
  custom_image
end
