module AzureCompute
  class VirtualMachine

    attr_reader :compute_service

    def initialize(credentials)
      @compute_service = Fog::Compute::AzureRM.new(credentials)
    end

    def get_resource_group_vms(resource_group_name)
      begin
        OOLog.info("Fetcing virtual machines in '#{resource_group_name}'")
        start_time = Time.now.to_i
        virtual_machines = @compute_service.servers(resource_group: resource_group_name)
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to get virtual machines #{vm_name} from resource group: #{resource_group_name}\n\r Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error getting VMs in resource group: #{resource_group_name}. Error Message: #{e.message}")
      end

      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_get_vms_in_rg=#{duration}" if ENV['KITCHEN_YAML'].nil?
      virtual_machines
    end

    def get(resource_group_name, vm_name)
      begin
        OOLog.info("Fetching VM '#{vm_name}' in '#{resource_group_name}' ")
        start_time = Time.now.to_i
        virtual_machine = @compute_service.servers.get(resource_group_name, vm_name)
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to get virtual machine #{vm_name} from resource group: #{resource_group_name}\n\rAzure::Virtual Machine - Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error fetching VM: #{vm_name}. Error Message: #{e.message}")
      end

      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_get_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      virtual_machine
    end

    def check_vm_exists?(resource_group_name, vm_name)
      begin
        start_time = Time.now.to_i
        exists = @compute_service.servers.check_vm_exists(resource_group_name, vm_name)
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to check VM: #{vm_params[:name]} existence. Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error checking VM: #{vm_params[:name]} existence. Error Message: #{e.message}")
      end
      OOLog.debug("VM Exists?: #{exists}")
      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_check_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      exists
    end

    def create_update(vm_params)
      begin
        OOLog.info("Creating/updating VM '#{vm_params[:name]}' in '#{vm_params[:resource_group]}' ")
        start_time = Time.now.to_i
        virtual_machine = @compute_service.servers.create(vm_params)
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to create/update virtual machine #{vm_params[:name]} from resource group: #{vm_params[:resource_group]}\n\rAzure::Virtual Machine - Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error creating/updating VM: #{vm_params[:name]}. Error Message: #{e.message}")
      end

      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_create_update_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      virtual_machine
    end

    def delete(resource_group_name, vm_name)
      begin
        OOLog.info("Deleting VM '#{vm_name}' in '#{resource_group_name}' ")
        start_time = Time.now.to_i
        virtual_machine_exists = @compute_service.servers.check_vm_exists(resource_group_name, vm_name)
        if !virtual_machine_exists
          OOLog.info("Virtual Machine '#{vm_name}' was not found in '#{resource_group_name}', skipping deletion..")
        else
          virtual_machine = get(resource_group_name, vm_name).destroy
        end
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to delete virtual machine #{vm_name} from resource group: #{resource_group_name}\n\rAzure::Virtual Machine - Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error deleting VM: #{vm_name}. Error Message: #{e.message}")
      end

      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_delete_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      true
    end

    def start(resource_group_name, vm_name)
      begin
        OOLog.info("Starting VM: #{vm_name} in resource group: #{resource_group_name}")
        start_time = Time.now.to_i
        virtual_machine = @compute_service.servers.get(resource_group_name, vm_name)
        response = virtual_machine.start
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to start virtual machine #{vm_name} from resource group: #{resource_group_name}\n\rAzure::Virtual Machine - Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error starting VM. #{vm_name}. Error Message: #{e.message}")
      end

      OOLog.info("VM started in #{duration} seconds")
      puts "***TAG:az_start_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      response
    end

    def restart(resource_group_name, vm_name)
      begin
        OOLog.info("Restarting VM: #{vm_name} in resource group: #{resource_group_name}")
        start_time = Time.now.to_i
        virtual_machine = @compute_service.servers.get(resource_group_name, vm_name)
        response = virtual_machine.restart
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to restart virtual machine #{vm_name} from resource group: #{resource_group_name}\n\rAzure::Virtual Machine - Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error restarting VM. #{vm_name}. Error Message: #{e.message}")
      end

      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_restart_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      response
    end

    def power_off(resource_group_name, vm_name)
      begin
        OOLog.info("Power off VM: #{vm_name} in resource group: #{resource_group_name}")
        start_time = Time.now.to_i
        virtual_machine = @compute_service.servers.get(resource_group_name, vm_name)
        response = virtual_machine.power_off
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to Power Off virtual machine #{vm_name} from resource group: #{resource_group_name}\n\rAzure::Virtual Machine - Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error powering off VM. #{vm_name}. Error Message: #{e.message}")
      end

      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_poweroff_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      response
    end

    def redeploy(resource_group_name, vm_name)
      begin
        OOLog.info("Redeploying VM: #{vm_name} in resource group: #{resource_group_name}")
        start_time = Time.now.to_i
        virtual_machine = @compute_service.servers.get(resource_group_name, vm_name)
        response = virtual_machine.redeploy
        end_time = Time.now.to_i
        duration = end_time - start_time
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Azure::Virtual Machine - Exception trying to redeploy virtual machine #{vm_name} from resource group: #{resource_group_name}\n\rAzure::Virtual Machine - Exception is: #{e.body}")
      rescue => e
        OOLog.fatal("Error redeploying VM. #{vm_name}. Error Message: #{e.message}")
      end

      OOLog.info("operation took #{duration} seconds")
      puts "***TAG:az_redeploy_vm=#{duration}" if ENV['KITCHEN_YAML'].nil?
      response
    end
  end
end
